/*
 * Habilita o deshabilita las partes visuales de cada página.
 *
 * Cada bloque administrable del HTML lleva el atributo data-seccion="clave".
 * La tabla "informacion_general" de Supabase guarda una fila por bloque con
 * su página, su clave, su título y si está habilitado; aquí se consulta esa
 * tabla y se quitan del DOM los bloques deshabilitados.
 *
 * Se incluye en el <head> de cada página:
 *   <script src="assets/js/secciones.js"></script>
 *
 * Si la consulta falla o tarda demasiado, la página se muestra completa.
 */
(function () {
    "use strict";

    var SUPABASE_URL = "https://gmcuzmsckwtdvurboobh.supabase.co";
    var SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdtY3V6bXNja3d0ZHZ1cmJvb2JoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3OTIyNDksImV4cCI6MjA5MjM2ODI0OX0.W0_WJnePVI9gXclM3NTQKvo7VLNAf5gQ2PPPc_X9QMk";
    var CDN_SUPABASE = "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2";
    var CLASE_CARGANDO = "secciones-cargando";
    var ESPERA_MAXIMA = 3000;

    // Oculta los bloques administrables hasta saber cuáles están habilitados,
    // para que los deshabilitados no alcancen a verse al abrir la página.
    var estilo = document.createElement("style");
    estilo.textContent = "." + CLASE_CARGANDO + " [data-seccion]{visibility:hidden}";
    document.head.appendChild(estilo);
    document.documentElement.classList.add(CLASE_CARGANDO);

    var revelado = false;
    function revelar() {
        revelado = true;
        document.documentElement.classList.remove(CLASE_CARGANDO);
    }
    setTimeout(function () { if (!revelado) revelar(); }, ESPERA_MAXIMA);

    // Nombre del archivo actual, tal como se guarda en la columna "pagina".
    function paginaActual() {
        var archivo = window.location.pathname.split("/").pop();
        return archivo ? archivo.toLowerCase() : "index.html";
    }

    function cargarLibreria() {
        if (window.supabase && window.supabase.createClient) return Promise.resolve();
        return new Promise(function (resolver, rechazar) {
            var etiqueta = document.createElement("script");
            etiqueta.src = CDN_SUPABASE;
            etiqueta.onload = resolver;
            etiqueta.onerror = rechazar;
            document.head.appendChild(etiqueta);
        });
    }

    // Quita los bloques cuya clave está marcada como no visible. Las claves que
    // no existan en la base de datos se dejan visibles.
    function aplicar(filas) {
        var deshabilitadas = {};
        filas.forEach(function (fila) {
            if (fila.visible === false) deshabilitadas[fila.clave] = true;
        });
        var bloques = document.querySelectorAll("[data-seccion]");
        Array.prototype.forEach.call(bloques, function (bloque) {
            if (deshabilitadas[bloque.getAttribute("data-seccion")]) {
                bloque.parentNode.removeChild(bloque);
            }
        });
    }

    // Inserta el contenido con formato (tabla contenido_secciones) en los
    // marcadores <... data-contenido="clave">. Solo se consulta si la página
    // tiene al menos un marcador, así las demás no pagan la consulta extra.
    function aplicarContenido(cliente) {
        var marcadores = document.querySelectorAll("[data-contenido]");
        if (marcadores.length === 0) return Promise.resolve();

        var claves = [];
        Array.prototype.forEach.call(marcadores, function (m) {
            var clave = m.getAttribute("data-contenido");
            if (claves.indexOf(clave) === -1) claves.push(clave);
        });

        return cliente
            .from("contenido_secciones")
            .select("seccion_clave, contenido")
            .in("seccion_clave", claves)
            .then(function (respuesta) {
                if (!respuesta || respuesta.error || !respuesta.data) return;
                var porClave = {};
                respuesta.data.forEach(function (fila) {
                    porClave[fila.seccion_clave] = fila.contenido;
                });
                Array.prototype.forEach.call(marcadores, function (m) {
                    var clave = m.getAttribute("data-contenido");
                    if (porClave[clave] != null) m.innerHTML = porClave[clave];
                });
            });
    }

    function aplicarSecciones() {
        var cliente;
        cargarLibreria()
            .then(function () {
                cliente = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY, {
                    global: {
                        fetch: function (url, opciones) {
                            return fetch(url, Object.assign({}, opciones, { cache: "no-store" }));
                        }
                    }
                });
                return cliente
                    .from("informacion_general")
                    .select("clave, visible")
                    .eq("pagina", paginaActual());
            })
            .then(function (respuesta) {
                if (respuesta && !respuesta.error && respuesta.data) aplicar(respuesta.data);
                return aplicarContenido(cliente);
            })
            .catch(function () {
                // Ante cualquier error se deja la página tal como está en el HTML.
            })
            .then(revelar);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", aplicarSecciones);
    } else {
        aplicarSecciones();
    }
})();
