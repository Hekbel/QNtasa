/**
 * App Controller - QuetzalNexuz
 * Conexión entre la interfaz de usuario (Frontend) y RateManager (Backend)
 */

(() => {
    'use strict';

    // Estado global de la aplicación
    const state = {
        rates: {
            1: {
                value: null,
                name: 'BCV (Oficial)',
                meta: 'Cargando...',
                source: 'dolarapi_oficial',
                isManual: false
            },
            2: {
                value: null,
                name: 'Paralelo',
                meta: 'Cargando...',
                source: 'dolarapi_paralelo',
                isManual: false
            }
        },
        currentView: 'dashboard', // 'dashboard' | 'table'
        calcCurrency: 'USD',      // 'USD' | 'VES'
        activeProvider: 'DolarApi & Yadio'
    };

    const RELEVANT_AMOUNTS = [1, 2, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100];

    // ==========================================
    // Formateadores
    // ==========================================
    function formatBs(val) {
        if (val === null || isNaN(val) || val === undefined) return '--';
        return new Intl.NumberFormat('es-VE', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(val) + ' Bs.';
    }

    function formatUSD(val) {
        if (val === null || isNaN(val) || val === undefined) return '--';
        return new Intl.NumberFormat('en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(val) + ' $';
    }

    // ==========================================
    // Manejo de Vistas (Dashboard / Tabla)
    // ==========================================
    function toggleView() {
        const dashboardView = document.getElementById('view-dashboard');
        const tableView = document.getElementById('view-table');
        const fabIcon = document.getElementById('fab-icon');
        const fabTooltip = document.getElementById('fab-tooltip');

        if (state.currentView === 'dashboard') {
            state.currentView = 'table';
            dashboardView.classList.add('hidden');
            tableView.classList.remove('hidden');

            fabIcon.className = 'fa-solid fa-house group-hover:rotate-12 transition-transform';
            fabTooltip.textContent = 'Volver al Panel Principal';

            renderConversionTable();
            window.scrollTo({ top: 0, behavior: 'smooth' });
        } else {
            state.currentView = 'dashboard';
            tableView.classList.add('hidden');
            dashboardView.classList.remove('hidden');

            fabIcon.className = 'fa-solid fa-table-list group-hover:rotate-12 transition-transform';
            fabTooltip.textContent = 'Ver Tabla de Conversión';
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }

    // ==========================================
    // Calculadora Rápida
    // ==========================================
    function setCalcCurrency(curr) {
        state.calcCurrency = curr;
        const btnUSD = document.getElementById('btn-curr-usd');
        const btnVES = document.getElementById('btn-curr-ves');

        if (curr === 'USD') {
            btnUSD.className = 'px-2.5 py-1 text-xs font-bold rounded-lg bg-gold-500 text-darkbg-900 transition-all';
            btnVES.className = 'px-2.5 py-1 text-xs font-bold rounded-lg bg-darkbg-700 text-gray-400 transition-all';
        } else {
            btnVES.className = 'px-2.5 py-1 text-xs font-bold rounded-lg bg-gold-500 text-darkbg-900 transition-all';
            btnUSD.className = 'px-2.5 py-1 text-xs font-bold rounded-lg bg-darkbg-700 text-gray-400 transition-all';
        }
        calculateConversion();
    }

    function calculateConversion() {
        const inputEl = document.getElementById('calc-amount');
        const amountInput = parseFloat(inputEl ? inputEl.value : 0) || 0;
        const res1 = document.getElementById('calc-result-1');
        const res2 = document.getElementById('calc-result-2');

        const r1 = state.rates[1].value;
        const r2 = state.rates[2].value;

        if (!r1 || !r2) {
            if (res1) res1.textContent = 'Esperando tasa...';
            if (res2) res2.textContent = 'Esperando tasa...';
            return;
        }

        if (state.calcCurrency === 'USD') {
            if (res1) res1.textContent = formatBs(amountInput * r1);
            if (res2) res2.textContent = formatBs(amountInput * r2);
        } else {
            if (res1) res1.textContent = formatUSD(amountInput / r1);
            if (res2) res2.textContent = formatUSD(amountInput / r2);
        }
    }

    // ==========================================
    // Renderizado de Tabla Comparativa
    // ==========================================
    function renderConversionTable() {
        const tbody = document.getElementById('conversion-table-body');
        const th1 = document.getElementById('table-th-1');
        const th2 = document.getElementById('table-th-2');

        const r1 = state.rates[1].value;
        const r2 = state.rates[2].value;

        if (th1) th1.textContent = `Monto ${state.rates[1].name} (Bs.)`;
        if (th2) th2.textContent = `Monto ${state.rates[2].name} (Bs.)`;

        if (!tbody) return;
        tbody.innerHTML = '';

        if (!r1 || !r2) {
            tbody.innerHTML = `<tr><td colspan="5" class="text-center py-6 text-gray-400">Las tasas aún se están sincronizando...</td></tr>`;
            return;
        }

        RELEVANT_AMOUNTS.forEach((usd, index) => {
            const val1 = usd * r1;
            const val2 = usd * r2;
            const diffBs = val2 - val1;
            const diffUSD = r1 > 0 ? diffBs / r1 : 0;

            const tr = document.createElement('tr');
            tr.className = index % 2 === 0
                ? 'bg-darkbg-800/40 hover:bg-darkbg-700/60 transition-colors'
                : 'bg-darkbg-900/40 hover:bg-darkbg-700/60 transition-colors';

            tr.innerHTML = `
                <td class="p-3.5 font-bold text-white font-heading">${formatUSD(usd)}</td>
                <td class="p-3.5 text-gray-200">${formatBs(val1)}</td>
                <td class="p-3.5 text-gold-400 font-semibold">${formatBs(val2)}</td>
                <td class="p-3.5 text-rose-400 font-semibold">+${formatBs(diffBs)}</td>
                <td class="p-3.5 text-emerald-400 font-bold font-heading">+${formatUSD(diffUSD)}</td>
            `;
            tbody.appendChild(tr);
        });
    }

    // ==========================================
    // Actualización de Métricas Globales y Brecha
    // ==========================================
    function updateGlobalStats(sourceLabel = null) {
        const r1 = state.rates[1].value;
        const r2 = state.rates[2].value;

        if (r1 && r2) {
            const gap = RateManager.calculateGap(r1, r2);

            const gapBsEl = document.getElementById('gap-bs-display');
            const gapPctEl = document.getElementById('gap-pct-display');
            const gap100El = document.getElementById('gap-100usd-display');
            const gapUsdEl = document.getElementById('gap-in-usd-display');

            if (gapBsEl) gapBsEl.textContent = `${gap.diffBs.toFixed(2)} Bs.`;
            if (gapPctEl) gapPctEl.textContent = `+${gap.diffPct.toFixed(2)}%`;
            if (gap100El) gap100El.textContent = formatBs(gap.diff100Usd);
            if (gapUsdEl) gapUsdEl.textContent = formatUSD(gap.diffInUSD);
        }

        calculateConversion();

        if (state.currentView === 'table') {
            renderConversionTable();
        }

        const updateTimeEl = document.getElementById('last-update-time');
        if (updateTimeEl) {
            const now = new Date().toLocaleTimeString('es-VE', { hour: '2-digit', minute: '2-digit' });
            updateTimeEl.textContent = `Actualizado: ${now}`;
        }

        if (sourceLabel) {
            const statusTag = document.getElementById('status-tag');
            if (statusTag) statusTag.textContent = sourceLabel;
        }
    }

    // ==========================================
    // Actualización Individual por Tarjeta
    // ==========================================
    async function fetchCardRate(cardId) {
        const icon = document.getElementById(`icon-refresh-${cardId}`);
        if (icon) icon.classList.add('fa-spin');

        const selectEl = document.getElementById(`api-select-${cardId}`);
        const sourceKey = selectEl ? selectEl.value : state.rates[cardId].source;

        state.rates[cardId].isManual = false;
        state.rates[cardId].source = sourceKey;

        try {
            const res = await RateManager.fetchSingleSource(sourceKey);
            state.rates[cardId].value = res.value;
            state.rates[cardId].meta = res.meta;

            renderCard(cardId, res.name, res.value, res.meta, res.source);
            updateGlobalStats();
        } catch (err) {
            console.warn(`[App] Error en tarjeta ${cardId}:`, err);
            const badge = document.getElementById(`status-badge-${cardId}`);
            if (badge) {
                badge.className = 'text-rose-400 font-medium';
                badge.innerHTML = '<i class="fa-solid fa-triangle-exclamation mr-1"></i>Error';
            }
        } finally {
            if (icon) {
                setTimeout(() => icon.classList.remove('fa-spin'), 400);
            }
        }
    }

    function onApiChange(cardId) {
        fetchCardRate(cardId);
    }

    // ==========================================
    // Actualización Maestra con Fallback SWR
    // ==========================================
    async function fetchAllRates(isManualClick = false) {
        const refreshIcon = document.getElementById('refresh-icon');
        if (refreshIcon) refreshIcon.classList.add('fa-spin');

        const statusBanner = document.getElementById('status-banner');
        const statusText = document.getElementById('status-text');
        const statusTag = document.getElementById('status-tag');

        if (statusBanner) statusBanner.classList.remove('hidden');
        if (statusText) statusText.textContent = 'Sincronizando tasas oficiales y de mercado...';

        try {
            // Actualizar tarjeta 1 y 2 en paralelo según sus selectores activos
            await Promise.all([
                fetchCardRate(1),
                fetchCardRate(2)
            ]);

            if (statusTag) statusTag.textContent = 'En línea';
            if (statusText) {
                statusText.textContent = 'Tasas sincronizadas con éxito.';
            }

            updateGlobalStats();
        } catch (err) {
            console.error('[App] Error al actualizar tasas maestras:', err);
            if (statusText) {
                statusText.textContent = 'Error al consultar algunos servidores. Mostrando valores locales.';
            }
        } finally {
            if (refreshIcon) {
                setTimeout(() => refreshIcon.classList.remove('fa-spin'), 400);
            }
        }
    }

    function renderCard(cardId, badgeText, val, metaText, providerName) {
        const badgeEl = document.getElementById(`card-badge-${cardId}`);
        const displayEl = document.getElementById(`rate-display-${cardId}`);
        const metaEl = document.getElementById(`meta-${cardId}`);
        const statusEl = document.getElementById(`status-badge-${cardId}`);

        if (badgeEl) {
            badgeEl.textContent = badgeText;
            badgeEl.className = cardId === 1
                ? 'px-2 py-0.5 rounded text-[10px] bg-blue-500/20 text-blue-300 border border-blue-500/30 font-bold'
                : 'px-2 py-0.5 rounded text-[10px] bg-gold-500/20 text-gold-300 border border-gold-500/30 font-bold';
        }
        if (displayEl) {
            displayEl.textContent = formatBs(val);
        }
        if (metaEl) {
            metaEl.textContent = metaText;
        }
        if (statusEl) {
            statusEl.className = 'text-emerald-400 font-medium';
            statusEl.innerHTML = '<i class="fa-solid fa-check-circle mr-1"></i>En línea';
        }
    }

    // ==========================================
    // Modal de Tasa Manual
    // ==========================================
    function openManualModal(cardId) {
        const modal = document.getElementById('manual-modal');
        const modalTitle = document.getElementById('modal-title');
        const cardInput = document.getElementById('manual-card-id');
        const valInput = document.getElementById('manual-input-val');

        if (cardInput) cardInput.value = cardId;
        if (modalTitle) modalTitle.textContent = `Editar Tasa Manual: Tarjeta ${cardId} (${state.rates[cardId].name})`;
        if (valInput) {
            valInput.value = state.rates[cardId].value || '';
            setTimeout(() => valInput.focus(), 50);
        }
        if (modal) modal.classList.remove('hidden');
    }

    function closeManualModal() {
        const modal = document.getElementById('manual-modal');
        if (modal) modal.classList.add('hidden');
    }

    function saveManualRate() {
        const cardIdInput = document.getElementById('manual-card-id');
        const valInput = document.getElementById('manual-input-val');

        const cardId = parseInt(cardIdInput ? cardIdInput.value : 1, 10);
        const val = parseFloat(valInput ? valInput.value : 0);

        if (!isNaN(val) && val > 0) {
            state.rates[cardId].value = val;
            state.rates[cardId].isManual = true;
            state.rates[cardId].meta = 'Ingresado manualmente';

            const displayEl = document.getElementById(`rate-display-${cardId}`);
            const metaEl = document.getElementById(`meta-${cardId}`);
            const badgeEl = document.getElementById(`card-badge-${cardId}`);

            if (displayEl) displayEl.textContent = formatBs(val);
            if (metaEl) metaEl.textContent = 'Modo Manual (Personalizado)';
            if (badgeEl) {
                badgeEl.textContent = 'Manual';
                badgeEl.className = 'px-2 py-0.5 rounded text-[10px] bg-amber-500/20 text-amber-300 border border-amber-500/30 font-bold';
            }

            updateGlobalStats();
            closeManualModal();
        } else {
            alert('Por favor ingrese un valor numérico válido mayor a cero.');
        }
    }

    // ==========================================
    // Inicialización Instantánea (0 ms con Caché)
    // ==========================================
    function init() {
        const yearSpan = document.getElementById('year-span');
        if (yearSpan) yearSpan.textContent = new Date().getFullYear();

        // 1. Mostrar de inmediato datos de caché si existen (SWR)
        const cached = RateManager.getStoredCache();
        if (cached && cached.bcv && cached.paralelo) {
            state.rates[1].value = cached.bcv;
            state.rates[1].meta = cached.metaBcv || 'Oficial (Caché)';
            renderCard(1, 'BCV Oficial (Caché)', cached.bcv, state.rates[1].meta, 'Caché Local');

            state.rates[2].value = cached.paralelo;
            state.rates[2].meta = cached.metaParalelo || 'Paralelo (Caché)';
            renderCard(2, 'Paralelo (Caché)', cached.paralelo, state.rates[2].meta, 'Caché Local');

            updateGlobalStats('Caché Local');
        }

        // 2. Disparar sincronización en red
        fetchAllRates(false);
    }

    // Exportar al ámbito global para handlers de eventos en el HTML
    window.toggleView = toggleView;
    window.setCalcCurrency = setCalcCurrency;
    window.calculateConversion = calculateConversion;
    window.fetchAllRates = () => fetchAllRates(true);
    window.fetchCardRate = fetchCardRate;
    window.onApiChange = onApiChange;
    window.openManualModal = openManualModal;
    window.closeManualModal = closeManualModal;
    window.saveManualRate = saveManualRate;

    // Escuchar cuando el DOM esté listo
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
