/*
 * Habilita o deshabilita las partes visuales de cada página.
 *
 * Cada bloque administrable del HTML lleva el atributo data-seccion="clave".
 * La tabla "informacion_general" de Supabase guarda una fila por bloque con
 * su página, su clave, su título y si está habilitado; aquí se consulta esa
 * tabla y se quitan del DOM los bloques deshabilitados.
 *
 * También cambia las imágenes marcadas con data-imagen="clave" por las que
 * estén guardadas en la tabla "imagenes_sitio" (admin.html > Imágenes del sitio).
 *
 * Además ofrece el cliente de Supabase compartido por toda la página:
 *   obtenerClienteSupabase().then(function (cliente) { ... });
 * Así la librería se descarga una sola vez y la clave vive en un solo lugar.
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
    var CDN_SUPABASE = "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.118.0";
    var CLASE_CARGANDO = "secciones-cargando";
    var ESPERA_MAXIMA = 3000;

    // Oculta los bloques administrables hasta saber cuáles están habilitados,
    // para que los deshabilitados no alcancen a verse al abrir la página.
    // Lo mismo con las imágenes administrables, para que no se vea la anterior.
    var estilo = document.createElement("style");
    estilo.textContent = "." + CLASE_CARGANDO + " [data-seccion]," +
        "." + CLASE_CARGANDO + " img[data-imagen]{visibility:hidden}";
    document.head.appendChild(estilo);
    document.documentElement.classList.add(CLASE_CARGANDO);

    var revelado = false;
    function revelar() {
        revelado = true;
        document.documentElement.classList.remove(CLASE_CARGANDO);
    }
    setTimeout(function () { if (!revelado) revelar(); }, ESPERA_MAXIMA);

    // Nombre del archivo actual, tal como se guarda en la columna "pagina".
    // Si el servidor sirve la página sin extensión (/inicio) se agrega ".html".
    function paginaActual() {
        var archivo = window.location.pathname.split("/").pop() || "";
        try { archivo = decodeURIComponent(archivo); } catch (e) { /* se deja tal cual */ }
        archivo = archivo.toLowerCase();
        if (!archivo) return "index.html";
        return archivo.indexOf(".") === -1 ? archivo + ".html" : archivo;
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

    // Cliente único de Supabase para toda la página (sin caché del navegador,
    // para que los cambios hechos en el panel se vean al recargar).
    var promesaCliente = null;
    function obtenerClienteSupabase() {
        if (!promesaCliente) {
            promesaCliente = cargarLibreria().then(function () {
                return window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY, {
                    global: {
                        fetch: function (url, opciones) {
                            return fetch(url, Object.assign({}, opciones, { cache: "no-store" }));
                        }
                    }
                });
            });
            // Si la librería no carga, la próxima llamada lo vuelve a intentar.
            promesaCliente.catch(function () { promesaCliente = null; });
        }
        return promesaCliente;
    }
    window.obtenerClienteSupabase = obtenerClienteSupabase;

    // Empieza a descargar la librería de inmediato, sin esperar al resto del HTML.
    obtenerClienteSupabase();

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

    // Valores distintos de un atributo entre varios elementos.
    function clavesUnicas(elementos, atributo) {
        var claves = [];
        Array.prototype.forEach.call(elementos, function (el) {
            var clave = el.getAttribute(atributo);
            if (clave && claves.indexOf(clave) === -1) claves.push(clave);
        });
        return claves;
    }

    // Inserta el contenido con formato (tabla contenido_secciones) en los
    // marcadores <... data-contenido="clave">. Solo se consulta si la página
    // tiene al menos un marcador, así las demás no pagan la consulta extra.
    function aplicarContenido(cliente) {
        var marcadores = document.querySelectorAll("[data-contenido]");
        if (marcadores.length === 0) return Promise.resolve();

        var claves = clavesUnicas(marcadores, "data-contenido");

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

    // Pone en cada elemento <... data-imagen="clave"> la imagen guardada en la
    // tabla imagenes_sitio:
    //   <img>             -> cambia src y, si hay uno guardado, el texto alternativo
    //   <link rel="icon"> -> cambia el ícono de la pestaña
    //   otro elemento     -> cambia su imagen de fondo
    // Si la clave no tiene imagen guardada se deja la del HTML.
    function aplicarImagenes(cliente) {
        var marcadores = document.querySelectorAll("[data-imagen]");
        if (marcadores.length === 0) return Promise.resolve();

        return cliente
            .from("imagenes_sitio")
            .select("clave, imagen_url, alt")
            .in("clave", clavesUnicas(marcadores, "data-imagen"))
            .then(function (respuesta) {
                if (!respuesta || respuesta.error || !respuesta.data) return;
                var porClave = {};
                respuesta.data.forEach(function (fila) {
                    porClave[fila.clave] = fila;
                });
                Array.prototype.forEach.call(marcadores, function (el) {
                    var fila = porClave[el.getAttribute("data-imagen")];
                    if (!fila) return;
                    var url = fila.imagen_url;
                    if (url) {
                        if (el.tagName === "IMG") {
                            if (el.getAttribute("src") !== url) el.setAttribute("src", url);
                        } else if (el.tagName === "LINK") {
                            if (el.getAttribute("href") !== url) {
                                el.removeAttribute("type"); // la nueva puede no ser PNG
                                el.setAttribute("href", url);
                            }
                        } else {
                            el.style.backgroundImage = 'url("' + url.replace(/["\\]/g, "\\$&") + '")';
                        }
                    }
                    if (fila.alt && el.tagName === "IMG") el.setAttribute("alt", fila.alt);
                });
            });
    }

    function ignorarError() {
        // Ante cualquier error se deja esa parte de la página tal como está en el HTML.
    }

    function aplicarSecciones() {
        obtenerClienteSupabase()
            .then(function (cliente) {
                var secciones = cliente
                    .from("informacion_general")
                    .select("clave, visible")
                    .eq("pagina", paginaActual())
                    .then(function (respuesta) {
                        if (respuesta && !respuesta.error && respuesta.data) aplicar(respuesta.data);
                        return aplicarContenido(cliente);
                    });
                // Las imágenes se consultan al mismo tiempo que las secciones.
                return Promise.all([
                    secciones.catch(ignorarError),
                    aplicarImagenes(cliente).catch(ignorarError)
                ]);
            })
            .catch(ignorarError)
            .then(revelar);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", aplicarSecciones);
    } else {
        aplicarSecciones();
    }
})();
