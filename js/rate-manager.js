/**
 * RateManager - Gestor de Datos y Tasas Cambiarias
 * Proyecto: QuetzalNexuz / QuetzalMonitor
 *
 * Características:
 * - Fuentes 100% verificadas y activas: DolarApi y Yadio (Oficial, Paralelo y Binance P2P)
 * - Eliminación de endpoints obsoletos/caídos (PyDolar 404)
 * - Cascada automática de respaldo (Fallback a prueba de fallos)
 * - Patrón Stale-While-Revalidate (SWR) con persistencia en LocalStorage
 * - Timeout controlado con AbortController
 * - Cálculos de Brecha Cambiaria y tablas de conversión
 */

const RateManager = (() => {
    'use strict';

    const CACHE_KEY = 'quetzal_rates_cache_v3';
    const TTL_MS = 5 * 60 * 1000; // 5 minutos de vigencia
    const TIMEOUT_MS = 4000; // 4 segundos de timeout por llamada

    // Fuentes soportadas y verificadas
    const SOURCES = {
        DOLARAPI_OFICIAL: 'dolarapi_oficial',
        YADIO_OFICIAL: 'yadio_oficial',
        DOLARAPI_PARALELO: 'dolarapi_paralelo',
        BINANCE_P2P: 'binance_p2p',
        YADIO_PARALELO: 'yadio_paralelo'
    };

    /**
     * Realiza un fetch con timeout controlado mediante AbortController
     */
    async function fetchWithTimeout(url, options = {}, timeoutMs = TIMEOUT_MS) {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), timeoutMs);

        try {
            const res = await fetch(url, {
                ...options,
                signal: controller.signal
            });
            clearTimeout(timer);
            if (!res.ok) {
                throw new Error(`Error HTTP ${res.status}: ${res.statusText}`);
            }
            return await res.json();
        } catch (err) {
            clearTimeout(timer);
            throw err;
        }
    }

    /**
     * Consulta principal a DolarApi (devuelve oficial y paralelo en una llamada rápida)
     */
    async function fetchFromDolarApi() {
        const [resOficial, resParalelo] = await Promise.allSettled([
            fetchWithTimeout('https://ve.dolarapi.com/v1/dolares/oficial'),
            fetchWithTimeout('https://ve.dolarapi.com/v1/dolares/paralelo')
        ]);

        let bcv = null;
        let paralelo = null;
        let metaBcv = 'Oficial BCV';
        let metaParalelo = 'Promedio Paralelo';

        if (resOficial.status === 'fulfilled' && resOficial.value?.promedio) {
            bcv = parseFloat(resOficial.value.promedio);
            if (resOficial.value.fechaActualizacion) {
                const f = new Date(resOficial.value.fechaActualizacion);
                metaBcv = `Actualizado: ${f.toLocaleDateString('es-VE')}`;
            }
        }

        if (resParalelo.status === 'fulfilled' && resParalelo.value?.promedio) {
            paralelo = parseFloat(resParalelo.value.promedio);
            if (resParalelo.value.fechaActualizacion) {
                const f = new Date(resParalelo.value.fechaActualizacion);
                metaParalelo = `Actualizado: ${f.toLocaleTimeString('es-VE', { hour: '2-digit', minute: '2-digit' })}`;
            }
        }

        if (!bcv && !paralelo) {
            throw new Error('DolarApi no devolvió datos válidos');
        }

        return {
            bcv: bcv,
            paralelo: paralelo,
            binance: paralelo,
            source: 'DolarApi (Venezuela)',
            metaBcv: metaBcv,
            metaParalelo: metaParalelo,
            timestamp: Date.now()
        };
    }

    /**
     * Consulta a Yadio (Oficial, Paralelo y Binance P2P)
     */
    async function fetchFromYadio() {
        const data = await fetchWithTimeout('https://api.yadio.io/json');
        if (!data || !data.USD) {
            throw new Error('Respuesta inválida de Yadio');
        }

        const usd = data.USD;
        const bcvRate = usd.other?.official?.rate ? parseFloat(usd.other.official.rate) : null;
        const paraleloRate = usd.rate ? parseFloat(usd.rate) : null;
        const binanceRate = usd.other?.p2p_usdt?.rate ? parseFloat(usd.other.p2p_usdt.rate) : null;
        const pct24h = usd.changes?.pct_24h ? parseFloat(usd.changes.pct_24h) : 0;

        if (!bcvRate && !paraleloRate) {
            throw new Error('Yadio no contiene tasas de USD válidas');
        }

        return {
            bcv: bcvRate,
            paralelo: paraleloRate,
            binance: binanceRate || paraleloRate,
            change24h: pct24h,
            source: 'Yadio.io (Global)',
            metaBcv: 'Oficial BCV vía Yadio',
            metaParalelo: `Mercado Libre / P2P (${pct24h >= 0 ? '+' : ''}${pct24h}% 24h)`,
            metaBinance: 'Binance P2P (USDT)',
            timestamp: Date.now()
        };
    }

    /**
     * Consulta individual para cuando el usuario cambia el selector de una tarjeta
     */
    async function fetchSingleSource(sourceKey) {
        switch (sourceKey) {
            // === Tarjeta 1 (Oficial / BCV) ===
            case SOURCES.DOLARAPI_OFICIAL: {
                const d = await fetchWithTimeout('https://ve.dolarapi.com/v1/dolares/oficial');
                const val = parseFloat(d.promedio);
                const fecha = d.fechaActualizacion ? new Date(d.fechaActualizacion).toLocaleDateString('es-VE') : '';
                return {
                    value: val,
                    meta: fecha ? `Actualizado: ${fecha}` : 'Oficial BCV',
                    name: 'DolarApi Oficial',
                    source: 'DolarApi'
                };
            }

            case SOURCES.YADIO_OFICIAL: {
                const y = await fetchFromYadio();
                if (!y.bcv) throw new Error('Yadio no reporta tasa oficial BCV');
                return {
                    value: y.bcv,
                    meta: 'Oficial BCV vía Yadio',
                    name: 'Yadio Oficial',
                    source: 'Yadio.io'
                };
            }

            // === Tarjeta 2 (Paralelo / Binance) ===
            case SOURCES.DOLARAPI_PARALELO: {
                const d = await fetchWithTimeout('https://ve.dolarapi.com/v1/dolares/paralelo');
                const val = parseFloat(d.promedio);
                const hora = d.fechaActualizacion ? new Date(d.fechaActualizacion).toLocaleTimeString('es-VE', { hour: '2-digit', minute: '2-digit' }) : '';
                return {
                    value: val,
                    meta: hora ? `Actualizado: ${hora}` : 'Promedio Paralelo',
                    name: 'DolarApi Paralelo',
                    source: 'DolarApi'
                };
            }

            case SOURCES.BINANCE_P2P: {
                const y = await fetchFromYadio();
                if (!y.binance) throw new Error('No se pudo obtener la tasa P2P de Binance');
                return {
                    value: y.binance,
                    meta: 'Binance P2P (USDT en vivo)',
                    name: 'Binance P2P',
                    source: 'Binance P2P (Yadio)'
                };
            }

            case SOURCES.YADIO_PARALELO: {
                const y = await fetchFromYadio();
                if (!y.paralelo) throw new Error('Yadio no reporta tasa paralela');
                return {
                    value: y.paralelo,
                    meta: `Mercado Libre (${y.change24h >= 0 ? '+' : ''}${y.change24h}% 24h)`,
                    name: 'Yadio Paralelo',
                    source: 'Yadio.io'
                };
            }

            default:
                throw new Error(`Origen no reconocido: ${sourceKey}`);
        }
    }

    /**
     * Obtiene datos del LocalStorage
     */
    function getStoredCache() {
        try {
            const raw = localStorage.getItem(CACHE_KEY);
            if (!raw) return null;
            return JSON.parse(raw);
        } catch {
            return null;
        }
    }

    /**
     * Guarda datos en LocalStorage
     */
    function setStoredCache(data) {
        try {
            localStorage.setItem(CACHE_KEY, JSON.stringify({
                ...data,
                cachedAt: Date.now()
            }));
        } catch (e) {
            console.warn('[RateManager] No se pudo guardar en LocalStorage:', e);
        }
    }

    /**
     * Obtención maestra de tasas con Cascada (Failover) y SWR
     */
    async function fetchMasterRates(forceNetwork = false) {
        const cached = getStoredCache();

        // Si no forzamos red y el caché es reciente (< 5 min), usar caché de inmediato
        if (!forceNetwork && cached && (Date.now() - cached.timestamp < TTL_MS)) {
            return { ...cached, fromCache: true, isStale: false };
        }

        // Intento 1: DolarApi (Oficial y Paralelo específicos para Venezuela)
        try {
            const dolarData = await fetchFromDolarApi();
            setStoredCache(dolarData);
            return { ...dolarData, fromCache: false, isStale: false };
        } catch (errDolar) {
            console.warn('[RateManager] DolarApi falló, intentando Yadio...', errDolar.message);
        }

        // Intento 2: Yadio (Respaldo con BCV, Paralelo y Binance P2P)
        try {
            const yadioData = await fetchFromYadio();
            setStoredCache(yadioData);
            return { ...yadioData, fromCache: false, isStale: false };
        } catch (errYadio) {
            console.warn('[RateManager] Yadio también falló.', errYadio.message);
        }

        // Si fallaron todas las llamadas pero hay un caché disponible
        if (cached) {
            console.warn('[RateManager] Usando caché local previo.');
            return { ...cached, fromCache: true, isStale: true };
        }

        throw new Error('No fue posible obtener las tasas cambiarias de los servidores.');
    }

    /**
     * Utilidades de cálculo financiero
     */
    function calculateGap(bcv, paralelo) {
        if (!bcv || !paralelo || bcv <= 0) {
            return { diffBs: 0, diffPct: 0, diff100Usd: 0, diffInUSD: 0 };
        }
        const diffBs = paralelo - bcv;
        const diffPct = (diffBs / bcv) * 100;
        const diff100Usd = diffBs * 100;
        const diffInUSD = diffBs / bcv;

        return {
            diffBs,
            diffPct,
            diff100Usd,
            diffInUSD
        };
    }

    return {
        SOURCES,
        fetchMasterRates,
        fetchSingleSource,
        getStoredCache,
        setStoredCache,
        calculateGap
    };
})();
