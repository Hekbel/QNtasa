<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QuetzalNexuz - Monitoreo de Divisas Venezuela</title>
    <meta name="description" content="Monitoreo en tiempo real de tasas cambiarias de Venezuela (BCV, Paralelo, Binance P2P) con Yadio API, calculadora interactiva y tabla de conversión.">
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        gold: {
                            100: '#FFF9E6',
                            300: '#FCE282',
                            400: '#F5CE42',
                            500: '#E5B842',
                            600: '#DFA828',
                            700: '#B88214',
                        },
                        darkbg: {
                            900: '#0B0E14',
                            800: '#121824',
                            700: '#1A2234',
                            600: '#242F46',
                        }
                    },
                    boxShadow: {
                        'gold-glow': '0 0 15px rgba(229, 184, 66, 0.25)',
                        'gold-glow-lg': '0 0 25px rgba(229, 184, 66, 0.4)',
                    }
                }
            }
        }
    </script>
    <!-- FontAwesome icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Google Fonts Inter & Outfit -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background-color: #0B0E14;
            color: #E2E8F0;
            overflow-x: hidden;
        }
        h1, h2, h3, h4, .font-heading {
            font-family: 'Outfit', sans-serif;
        }
        .gold-gradient-text {
            background: linear-gradient(135deg, #FFF0B3 0%, #E5B842 50%, #B88214 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .gold-border-glow {
            border: 1px solid rgba(229, 184, 66, 0.3);
            transition: all 0.3s ease;
        }
        .gold-border-glow:hover {
            border-color: rgba(229, 184, 66, 0.7);
            box-shadow: 0 0 18px rgba(229, 184, 66, 0.25);
        }
        .custom-scrollbar::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
            background: #121824;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
            background: #E5B842;
            border-radius: 3px;
        }
        /* Glassmorphism */
        .glass-panel {
            background: rgba(18, 24, 36, 0.75);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid rgba(229, 184, 66, 0.18);
        }
        @media (prefers-reduced-motion: reduce) {
            * {
                animation: none !important;
                transition: none !important;
            }
        }
    </style>
</head>
<body class="min-h-screen flex flex-col justify-between selection:bg-gold-500 selection:text-black">

    <!-- Navbar / Top Bar -->
    <header class="w-full glass-panel sticky top-0 z-40 border-b border-gold-500/20 shadow-md">
        <div class="max-w-6xl mx-auto px-4 py-3 flex justify-between items-center">
            <div class="flex items-center space-x-3">
                <div class="p-2 rounded-lg bg-darkbg-700 border border-gold-500/30 flex items-center justify-center shadow-inner">
                    <!-- SVG Logo Icon de Quetzal / Finanzas -->
                    <svg class="h-8 w-8 text-gold-400" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                    </svg>
                </div>
                <div>
                    <h1 class="text-xl md:text-2xl font-bold font-heading gold-gradient-text tracking-wide">QuetzalNexuz</h1>
                    <p class="text-xs text-gray-400 font-medium">Finanzas & Divisas Venezuela</p>
                </div>
            </div>

            <div class="flex items-center space-x-2 md:space-x-4">
                <button onclick="fetchAllRates()" id="btn-refresh" aria-label="Actualizar todas las tasas" class="px-3 py-1.5 rounded-lg bg-darkbg-700 hover:bg-darkbg-600 border border-gold-500/40 text-gold-400 text-xs md:text-sm font-semibold flex items-center space-x-2 transition-all duration-300 hover:shadow-gold-glow cursor-pointer">
                    <i id="refresh-icon" class="fa-solid fa-rotate" aria-hidden="true"></i>
                    <span class="hidden sm:inline">Actualizar Todo</span>
                </button>
                <div class="hidden md:flex items-center space-x-2 text-xs text-gray-400 bg-darkbg-900/60 px-3 py-1.5 rounded-lg border border-gray-800">
                    <span class="inline-block w-2 h-2 rounded-full bg-emerald-500 animate-pulse" aria-hidden="true"></span>
                    <span id="last-update-time">Iniciando...</span>
                </div>
            </div>
        </div>
    </header>

    <main class="max-w-6xl w-full mx-auto px-4 py-6 flex-grow">

        <!-- VIEW 1: Main Dashboard (Shown by default) -->
        <div id="view-dashboard" class="space-y-6 transition-all duration-300">
            
            <!-- Source Status Bar -->
            <div id="status-banner" class="hidden p-3 rounded-xl border border-gold-500/20 bg-darkbg-800/80 text-xs md:text-sm flex items-center justify-between">
                <div class="flex items-center space-x-2">
                    <i class="fa-solid fa-bolt text-gold-400" aria-hidden="true"></i>
                    <span id="status-text" class="text-gray-300">Sincronizando orígenes de datos...</span>
                </div>
                <span id="status-tag" class="px-2 py-0.5 text-[10px] rounded uppercase font-bold bg-gold-500/20 text-gold-400 border border-gold-500/30">Yadio.io</span>
            </div>

            <!-- Rates Grid Section -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                
                <!-- Card 1 (BCV / Oficial) -->
                <div class="glass-panel p-6 rounded-2xl gold-border-glow relative overflow-hidden group">
                    <div class="absolute -right-6 -bottom-6 opacity-5 group-hover:opacity-10 transition-opacity pointer-events-none">
                        <i class="fa-solid fa-building-columns text-9xl text-gold-400" aria-hidden="true"></i>
                    </div>
                    
                    <!-- Card Header with Title and Controls -->
                    <div class="flex justify-between items-start mb-3 gap-2">
                        <div class="flex items-center space-x-3">
                            <div class="w-10 h-10 rounded-xl bg-blue-900/40 border border-blue-500/30 flex items-center justify-center text-blue-400 text-lg flex-shrink-0">
                                <i class="fa-solid fa-building-columns" aria-hidden="true"></i>
                            </div>
                            <div>
                                <h2 class="text-base md:text-lg font-bold text-white font-heading">Banco Central (BCV)</h2>
                                <p class="text-xs text-gray-400">Tasa Oficial de Cambio</p>
                            </div>
                        </div>

                        <!-- Controls: API Selector + Refresh Card + Manual Edit Pencil -->
                        <div class="flex items-center space-x-1.5">
                            <select id="api-select-1" onchange="onApiChange(1)" aria-label="Seleccionar proveedor de tasa oficial" class="bg-darkbg-900 border border-gold-500/30 text-gold-400 text-[11px] rounded-lg px-2 py-1 focus:outline-none focus:border-gold-500 cursor-pointer">
                                <option value="dolarapi_oficial" selected>DolarApi (BCV Oficial)</option>
                                <option value="yadio_oficial">Yadio (BCV Oficial)</option>
                            </select>

                            <button onclick="fetchCardRate(1)" title="Actualizar esta tarjeta" aria-label="Actualizar tarjeta BCV" class="w-7 h-7 rounded-lg bg-darkbg-700 hover:bg-darkbg-600 border border-gold-500/30 text-gold-400 flex items-center justify-center text-xs transition-all cursor-pointer">
                                <i id="icon-refresh-1" class="fa-solid fa-rotate-right" aria-hidden="true"></i>
                            </button>

                            <button onclick="openManualModal(1)" title="Modificar tasa manualmente" aria-label="Editar tasa BCV manualmente" class="w-7 h-7 rounded-lg bg-darkbg-700 hover:bg-darkbg-600 border border-gray-700 text-gray-400 hover:text-gold-400 flex items-center justify-center text-xs transition-all cursor-pointer">
                                <i class="fa-solid fa-pen" aria-hidden="true"></i>
                            </button>
                        </div>
                    </div>

                    <div class="my-4">
                        <div class="flex items-center space-x-2">
                            <span class="text-xs text-gray-400 uppercase font-semibold">Tasa Activa:</span>
                            <span id="card-badge-1" class="px-2 py-0.5 rounded text-[10px] bg-blue-500/20 text-blue-300 border border-blue-500/30 font-bold">BCV Oficial</span>
                        </div>
                        <div id="rate-display-1" class="text-3xl md:text-4xl font-extrabold text-white tracking-tight font-heading mt-1">
                            <span class="animate-pulse text-gray-500">Cargando...</span>
                        </div>
                        <p class="text-xs text-gray-400 mt-1" id="meta-1">Consultando proveedor...</p>
                    </div>

                    <div class="pt-4 border-t border-gray-800/80 flex justify-between items-center text-xs text-gray-400">
                        <span>Origen Activo</span>
                        <span id="status-badge-1" class="text-emerald-400 font-medium"><i class="fa-solid fa-check-circle mr-1" aria-hidden="true"></i>En línea</span>
                    </div>
                </div>

                <!-- Card 2 (Paralelo / Binance) -->
                <div class="glass-panel p-6 rounded-2xl gold-border-glow relative overflow-hidden group">
                    <div class="absolute -right-6 -bottom-6 opacity-5 group-hover:opacity-10 transition-opacity pointer-events-none">
                        <i class="fa-solid fa-coins text-9xl text-gold-400" aria-hidden="true"></i>
                    </div>

                    <!-- Card Header with Title and Controls -->
                    <div class="flex justify-between items-start mb-3 gap-2">
                        <div class="flex items-center space-x-3">
                            <div class="w-10 h-10 rounded-xl bg-amber-900/40 border border-gold-500/40 flex items-center justify-center text-gold-400 text-lg flex-shrink-0">
                                <i class="fa-solid fa-bolt" aria-hidden="true"></i>
                            </div>
                            <div>
                                <h2 class="text-base md:text-lg font-bold text-white font-heading">Paralelo / Binance</h2>
                                <p class="text-xs text-gray-400">Promedio Dólar Paralelo & P2P</p>
                            </div>
                        </div>

                        <!-- Controls: API Selector + Refresh Card + Manual Edit Pencil -->
                        <div class="flex items-center space-x-1.5">
                            <select id="api-select-2" onchange="onApiChange(2)" aria-label="Seleccionar proveedor de tasa paralela" class="bg-darkbg-900 border border-gold-500/30 text-gold-400 text-[11px] rounded-lg px-2 py-1 focus:outline-none focus:border-gold-500 cursor-pointer">
                                <option value="dolarapi_paralelo" selected>DolarApi (Paralelo)</option>
                                <option value="binance_p2p">Binance P2P (vía Yadio)</option>
                                <option value="yadio_paralelo">Yadio (Mercado Libre)</option>
                            </select>

                            <button onclick="fetchCardRate(2)" title="Actualizar esta tarjeta" aria-label="Actualizar tarjeta paralelo" class="w-7 h-7 rounded-lg bg-darkbg-700 hover:bg-darkbg-600 border border-gold-500/30 text-gold-400 flex items-center justify-center text-xs transition-all cursor-pointer">
                                <i id="icon-refresh-2" class="fa-solid fa-rotate-right" aria-hidden="true"></i>
                            </button>

                            <button onclick="openManualModal(2)" title="Modificar tasa manualmente" aria-label="Editar tasa paralela manualmente" class="w-7 h-7 rounded-lg bg-darkbg-700 hover:bg-darkbg-600 border border-gray-700 text-gray-400 hover:text-gold-400 flex items-center justify-center text-xs transition-all cursor-pointer">
                                <i class="fa-solid fa-pen" aria-hidden="true"></i>
                            </button>
                        </div>
                    </div>

                    <div class="my-4">
                        <div class="flex items-center space-x-2">
                            <span class="text-xs text-gray-400 uppercase font-semibold">Tasa Activa:</span>
                            <span id="card-badge-2" class="px-2 py-0.5 rounded text-[10px] bg-gold-500/20 text-gold-300 border border-gold-500/30 font-bold">Paralelo</span>
                        </div>
                        <div id="rate-display-2" class="text-3xl md:text-4xl font-extrabold text-gold-400 tracking-tight font-heading mt-1">
                            <span class="animate-pulse text-gray-500">Cargando...</span>
                        </div>
                        <p class="text-xs text-gray-400 mt-1" id="meta-2">Mercado Libre / P2P</p>
                    </div>

                    <div class="pt-4 border-t border-gray-800/80 flex justify-between items-center text-xs text-gray-400">
                        <span>Origen Activo</span>
                        <span id="status-badge-2" class="text-emerald-400 font-medium"><i class="fa-solid fa-check-circle mr-1" aria-hidden="true"></i>En línea</span>
                    </div>
                </div>

            </div>

            <!-- Gap / Difference Summary Banner -->
            <div class="glass-panel p-6 rounded-2xl border border-gold-500/30 bg-gradient-to-r from-darkbg-800 via-darkbg-700 to-darkbg-800">
                <div class="flex flex-col md:flex-row items-center justify-between gap-4">
                    <div class="flex items-center space-x-4 w-full md:w-auto">
                        <div class="p-3 rounded-2xl bg-gold-500/10 border border-gold-500/30 text-gold-400 text-2xl flex-shrink-0">
                            <i class="fa-solid fa-chart-line" aria-hidden="true"></i>
                        </div>
                        <div>
                            <h3 class="text-sm uppercase tracking-wider text-gray-400 font-semibold">Brecha Cambiaria (Diferencia)</h3>
                            <div class="flex items-baseline space-x-3 mt-1">
                                <span id="gap-bs-display" class="text-2xl md:text-3xl font-extrabold text-white font-heading">-- Bs.</span>
                                <span id="gap-pct-display" class="text-sm font-bold px-2.5 py-0.5 rounded-md bg-gold-500/20 text-gold-300 border border-gold-500/30">
                                    -- %
                                </span>
                            </div>
                        </div>
                    </div>

                    <div class="w-full md:w-auto grid grid-cols-2 gap-4 pt-3 md:pt-0 border-t md:border-t-0 border-gray-800 text-right">
                        <div class="bg-darkbg-900/60 p-3 rounded-xl border border-gray-800/80 text-left md:text-right">
                            <p class="text-[11px] text-gray-400">Diferencia x $100 USD</p>
                            <p id="gap-100usd-display" class="text-lg font-bold text-gold-400 font-heading">-- Bs.</p>
                        </div>
                        <div class="bg-darkbg-900/60 p-3 rounded-xl border border-gray-800/80 text-left md:text-right">
                            <p class="text-[11px] text-gray-400">Equivalente Dólares BCV</p>
                            <p id="gap-in-usd-display" class="text-lg font-bold text-emerald-400 font-heading">-- $</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Interactive Calculator Section -->
            <div class="glass-panel p-6 rounded-2xl gold-border-glow">
                <div class="flex items-center space-x-3 mb-5">
                    <div class="p-2 rounded-lg bg-gold-500/10 text-gold-400">
                        <i class="fa-solid fa-calculator" aria-hidden="true"></i>
                    </div>
                    <h3 class="text-lg font-bold text-white font-heading">Calculadora de Conversión Rápida</h3>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-12 gap-4 items-center">
                    <!-- Amount Input -->
                    <div class="md:col-span-5 space-y-1">
                        <label for="calc-amount" class="text-xs font-semibold text-gray-400 uppercase">Monto a Convertir</label>
                        <div class="relative">
                            <input type="number" id="calc-amount" value="10" min="0" step="any" 
                                class="w-full bg-darkbg-900 border border-gray-700 focus:border-gold-500 rounded-xl px-4 py-3 text-white text-lg font-bold font-heading focus:outline-none focus:ring-1 focus:ring-gold-500 transition-all"
                                placeholder="0.00" oninput="calculateConversion()">
                            <div class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center space-x-1">
                                <button onclick="setCalcCurrency('USD')" id="btn-curr-usd" class="px-2.5 py-1 text-xs font-bold rounded-lg bg-gold-500 text-darkbg-900 transition-all cursor-pointer">USD</button>
                                <button onclick="setCalcCurrency('VES')" id="btn-curr-ves" class="px-2.5 py-1 text-xs font-bold rounded-lg bg-darkbg-700 text-gray-400 transition-all cursor-pointer">VES</button>
                            </div>
                        </div>
                    </div>

                    <!-- Swap Icon indicator -->
                    <div class="md:col-span-1 flex justify-center py-2 md:py-0">
                        <div class="w-10 h-10 rounded-full bg-darkbg-700 border border-gray-700 flex items-center justify-center text-gold-400">
                            <i class="fa-solid fa-arrows-rotate" aria-hidden="true"></i>
                        </div>
                    </div>

                    <!-- Calculation Results -->
                    <div class="md:col-span-6 grid grid-cols-2 gap-3">
                        <div class="p-3 rounded-xl bg-darkbg-900/80 border border-gray-800">
                            <p class="text-xs text-gray-400 mb-1" id="calc-label-1">Monto en BCV:</p>
                            <p id="calc-result-1" class="text-base md:text-lg font-bold text-white font-heading">0.00 Bs.</p>
                        </div>
                        <div class="p-3 rounded-xl bg-darkbg-900/80 border border-gold-500/30">
                            <p class="text-xs text-gold-400 mb-1" id="calc-label-2">Monto en Paralelo:</p>
                            <p id="calc-result-2" class="text-base md:text-lg font-bold text-gold-400 font-heading">0.00 Bs.</p>
                        </div>
                    </div>
                </div>
            </div>

        </div>

        <!-- VIEW 2: Full Table Conversion View -->
        <div id="view-table" class="hidden space-y-6 transition-all duration-300">
            <div class="glass-panel p-6 rounded-2xl gold-border-glow">
                <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6 pb-4 border-b border-gray-800">
                    <div>
                        <div class="flex items-center space-x-2">
                            <span class="px-2.5 py-1 rounded-md bg-gold-500/20 text-gold-400 border border-gold-500/30 text-xs font-bold uppercase">
                                Vista Detallada
                            </span>
                            <h2 class="text-2xl font-extrabold text-white font-heading">Tabla de Conversión USD / VES</h2>
                        </div>
                        <p class="text-xs text-gray-400 mt-1">Comparativa detallada de valores de $1 a $100 con cálculo de brecha cambiaria</p>
                    </div>

                    <button onclick="toggleView()" class="px-4 py-2 rounded-xl bg-gold-500 hover:bg-gold-400 text-darkbg-900 font-bold text-xs flex items-center space-x-2 transition-all cursor-pointer">
                        <i class="fa-solid fa-arrow-left" aria-hidden="true"></i>
                        <span>Volver al Panel Principal</span>
                    </button>
                </div>

                <!-- Conversion Table -->
                <div class="overflow-x-auto custom-scrollbar">
                    <table class="w-full text-left border-collapse">
                        <thead>
                            <tr class="bg-darkbg-900/90 text-gold-400 text-xs uppercase tracking-wider border-b border-gold-500/30">
                                <th class="p-3.5 rounded-l-xl">Monto ($ USD)</th>
                                <th class="p-3.5" id="table-th-1">Monto BCV (Bs.)</th>
                                <th class="p-3.5" id="table-th-2">Monto Paralelo (Bs.)</th>
                                <th class="p-3.5">Diferencia (Bs.)</th>
                                <th class="p-3.5 rounded-r-xl">Equiv. Dólares (Tasa 1)</th>
                            </tr>
                        </thead>
                        <tbody id="conversion-table-body" class="divide-y divide-gray-800/60 text-sm">
                            <tr>
                                <td colspan="5" class="text-center py-8 text-gray-500">Cargando datos de conversión...</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div class="mt-4 pt-4 border-t border-gray-800/80 flex flex-col sm:flex-row justify-between items-center text-xs text-gray-400">
                    <p>* Los cálculos se realizan con las tasas dinámicas seleccionadas en tiempo real.</p>
                    <p class="mt-2 sm:mt-0">QuetzalNexuz &copy; <span id="year-span"></span></p>
                </div>
            </div>
        </div>

    </main>

    <!-- Footer -->
    <footer class="w-full border-t border-gray-800/80 py-4 bg-darkbg-900/80">
        <div class="max-w-6xl mx-auto px-4 flex flex-col sm:flex-row justify-between items-center text-xs text-gray-500 gap-2">
            <div class="flex items-center space-x-2">
                <svg class="h-4 w-4 text-gold-400 opacity-80" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                    <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                </svg>
                <span class="font-medium text-gray-400">QuetzalNexuz</span>
            </div>
            <p>Plataforma de Consulta Informativa de Tasas de Cambio • Datos vía Yadio & BCV</p>
        </div>
    </footer>

    <!-- Manual Edit Modal -->
    <div id="manual-modal" class="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center hidden p-4" role="dialog" aria-modal="true" aria-labelledby="modal-title">
        <div class="glass-panel p-6 rounded-2xl border border-gold-500/50 max-w-sm w-full shadow-2xl space-y-4">
            <div class="flex justify-between items-center pb-3 border-b border-gray-800">
                <h3 id="modal-title" class="text-base font-bold text-white font-heading">Establecer Tasa Manual</h3>
                <button onclick="closeManualModal()" aria-label="Cerrar ventana modal" class="text-gray-400 hover:text-white cursor-pointer"><i class="fa-solid fa-xmark text-lg" aria-hidden="true"></i></button>
            </div>
            <div>
                <label for="manual-input-val" class="text-xs text-gray-400 block mb-1">Nuevo valor de tasa en Bolívares (VES):</label>
                <input type="number" id="manual-input-val" step="any" class="w-full bg-darkbg-900 border border-gold-500/40 rounded-xl px-4 py-2.5 text-white font-bold text-lg focus:outline-none focus:border-gold-500" placeholder="0.00">
                <input type="hidden" id="manual-card-id">
            </div>
            <div class="flex space-x-3 pt-2">
                <button onclick="closeManualModal()" class="w-1/2 py-2 rounded-xl bg-darkbg-700 hover:bg-darkbg-600 text-gray-300 text-xs font-bold transition-all cursor-pointer">Cancelar</button>
                <button onclick="saveManualRate()" class="w-1/2 py-2 rounded-xl bg-gold-500 hover:bg-gold-400 text-darkbg-900 text-xs font-bold transition-all cursor-pointer">Guardar Tasa</button>
            </div>
        </div>
    </div>

    <!-- Circular Floating Action Button (FAB) Bottom-Right -->
    <button id="fab-toggle" onclick="toggleView()" aria-label="Alternar vista de tabla de conversión" class="fixed bottom-6 right-6 w-14 h-14 rounded-full bg-gradient-to-tr from-gold-600 via-gold-500 to-gold-400 text-darkbg-900 shadow-gold-glow-lg flex items-center justify-center text-xl z-50 hover:scale-110 active:scale-95 transition-all duration-300 group border-2 border-gold-300 cursor-pointer">
        <i id="fab-icon" class="fa-solid fa-table-list group-hover:rotate-12 transition-transform" aria-hidden="true"></i>
        <!-- Tooltip -->
        <span id="fab-tooltip" class="absolute right-16 top-1/2 -translate-y-1/2 bg-darkbg-800 text-gold-400 text-xs font-bold py-1.5 px-3 rounded-lg border border-gold-500/30 whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none shadow-lg">
            Ver Tabla de Conversión
        </span>
    </button>

    <!-- Scripts de la Aplicación -->
    <script src="js/rate-manager.js"></script>
    <script src="js/app.js"></script>
</body>
</html>
