/*
 * Habilita o deshabilita las partes visuales de cada página.
 *
 * Cada bloque administrable del HTML lleva el atributo data-seccion="clave".
 * La tabla "informacion_general" de Supabase guarda una fila por bloque con
 * su página, su clave, su título, su orden y si está habilitado; aquí se
 * consulta esa tabla, se quitan del DOM los bloques deshabilitados y los demás
 * se acomodan según su orden (admin.html > Secciones de la web).
 *
 * Pone en los elementos marcados con data-contenido="clave" el texto guardado
 * en la tabla "contenido_secciones" (admin.html > Contenido de secciones).
 *
 * También cambia las imágenes marcadas con data-imagen="clave" por las que
 * estén guardadas en la tabla "imagenes_sitio" (admin.html > Imágenes del sitio).
 *
 * Arma el menú superior (la lista marcada con data-menu) con las opciones
 * visibles de la tabla "menu", en su orden (admin.html > Menú).
 *
 * Aplica a los títulos y subtítulos el tipo de letra, el tamaño y el color de
 * la tabla "estilos_titulos" (admin.html > Configuración > Estilos de títulos).
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
    // Lo mismo con los textos e imágenes administrables, para que no se vea
    // la versión anterior antes de la guardada en el panel. El menú también,
    // para que no se vean las opciones en el orden anterior.
    var estilo = document.createElement("style");
    estilo.textContent = "." + CLASE_CARGANDO + " [data-seccion]," +
        "." + CLASE_CARGANDO + " [data-contenido]," +
        "." + CLASE_CARGANDO + " [data-menu]," +
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

    // Quita los bloques (data-seccion) y textos (data-contenido) cuya clave está
    // marcada como no visible. Las claves que no existan en la base de datos
    // se dejan visibles.
    function aplicar(filas) {
        var deshabilitadas = {};
        filas.forEach(function (fila) {
            if (fila.visible === false) deshabilitadas[fila.clave] = true;
        });
        var bloques = document.querySelectorAll("[data-seccion], [data-contenido]");
        Array.prototype.forEach.call(bloques, function (bloque) {
            if (deshabilitadas[bloque.getAttribute("data-seccion")] ||
                deshabilitadas[bloque.getAttribute("data-contenido")]) {
                if (bloque.parentNode) bloque.parentNode.removeChild(bloque);
            }
        });
    }

    // Acomoda los bloques (data-seccion) y textos (data-contenido) según la columna
    // "orden" (menor primero). Cada uno cambia de lugar solo con sus hermanos marcados,
    // es decir, los que están en el mismo contenedor: las secciones de la página entre
    // sí, el título y el texto de una sección entre sí, etc. Lo que no está marcado
    // (menú, pie de página, scripts) y lo que no tiene orden en la tabla se queda
    // donde está en el HTML. Con el mismo orden se respeta el del HTML, así que los
    // elementos que comparten clave (ej: el título y la tabla de "Fincas") siguen juntos.
    function ordenar(filas) {
        var ordenPorClave = {};
        filas.forEach(function (fila) {
            if (fila.orden != null && isFinite(fila.orden)) ordenPorClave[fila.clave] = Number(fila.orden);
        });
        function ordenDe(el) {
            var claves = [el.getAttribute("data-seccion"), el.getAttribute("data-contenido")];
            for (var i = 0; i < claves.length; i++) {
                if (claves[i] && Object.prototype.hasOwnProperty.call(ordenPorClave, claves[i])) {
                    return ordenPorClave[claves[i]];
                }
            }
            return null;
        }

        // Agrupa los elementos con orden por contenedor, en el orden del HTML.
        var contenedores = [];
        var grupos = [];
        var elementos = document.querySelectorAll("[data-seccion], [data-contenido]");
        Array.prototype.forEach.call(elementos, function (el, posicion) {
            var orden = ordenDe(el);
            if (orden === null || !el.parentNode) return;
            var i = contenedores.indexOf(el.parentNode);
            if (i === -1) {
                i = contenedores.push(el.parentNode) - 1;
                grupos.push([]);
            }
            grupos[i].push({ el: el, orden: orden, posicion: posicion });
        });

        grupos.forEach(function (grupo) {
            if (grupo.length < 2) return;
            var ordenados = grupo.slice().sort(function (a, b) {
                return a.orden - b.orden || a.posicion - b.posicion;
            });
            // Lugares que cambian de elemento. Los que ya están bien no se tocan
            // (mover un elemento recarga sus videos e iframes).
            var lugares = [];
            grupo.forEach(function (actual, i) {
                if (ordenados[i] !== actual) {
                    var marca = document.createComment("");
                    actual.el.parentNode.insertBefore(marca, actual.el);
                    lugares.push({ marca: marca, nuevo: ordenados[i].el });
                }
            });
            lugares.forEach(function (lugar) {
                lugar.marca.parentNode.replaceChild(lugar.nuevo, lugar.marca);
            });
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

    // Trae el texto con formato (tabla contenido_secciones) de los marcadores
    // <... data-contenido="clave"> de la página. Solo se consulta si la página
    // tiene al menos un marcador. Devuelve { clave: html }.
    function consultarContenido(cliente) {
        var marcadores = document.querySelectorAll("[data-contenido]");
        if (marcadores.length === 0) return Promise.resolve(null);

        return cliente
            .from("contenido_secciones")
            .select("seccion_clave, contenido")
            .in("seccion_clave", clavesUnicas(marcadores, "data-contenido"))
            .then(function (respuesta) {
                if (!respuesta || respuesta.error || !respuesta.data) return null;
                var porClave = {};
                respuesta.data.forEach(function (fila) {
                    porClave[fila.seccion_clave] = fila.contenido;
                });
                return porClave;
            });
    }

    // Títulos, párrafos y otros elementos que solo admiten texto: ahí no se
    // pueden poner los <p> del editor, así que cada <p> pasa a ser una línea
    // separada con <br> y el elemento conserva su propio estilo.
    var SOLO_TEXTO = /^(H[1-6]|P|SPAN|A|LABEL|BUTTON|SMALL|STRONG|EM)$/;

    function escaparTexto(texto) {
        var div = document.createElement("div");
        div.textContent = texto;
        return div.innerHTML;
    }

    function comoLineas(html) {
        var temporal = document.createElement("div");
        temporal.innerHTML = html;
        var lineas = [];
        Array.prototype.forEach.call(temporal.childNodes, function (nodo) {
            if (nodo.nodeType === 1 && /^(P|DIV|H[1-6]|BLOCKQUOTE|PRE)$/.test(nodo.tagName)) {
                lineas.push(nodo.innerHTML === "<br>" ? "" : nodo.innerHTML);
            } else if (nodo.nodeType === 1 && /^(OL|UL)$/.test(nodo.tagName)) {
                // Listas del editor: una línea por elemento, con viñeta o número.
                Array.prototype.forEach.call(nodo.children, function (li, i) {
                    var numerada = li.getAttribute("data-list") === "ordered" ||
                        (nodo.tagName === "OL" && !li.hasAttribute("data-list"));
                    lineas.push((numerada ? (i + 1) + ". " : "• ") + li.innerHTML);
                });
            } else {
                // Texto suelto (sin <p>): se suma a la línea en curso.
                if (lineas.length === 0) lineas.push("");
                lineas[lineas.length - 1] += nodo.nodeType === 1 ? nodo.outerHTML : escaparTexto(nodo.textContent);
            }
        });
        return lineas.join("<br>");
    }

    // Pone el texto guardado en cada marcador. Sin texto guardado, queda el del HTML.
    function ponerContenido(porClave) {
        if (!porClave) return;
        Array.prototype.forEach.call(document.querySelectorAll("[data-contenido]"), function (m) {
            var html = porClave[m.getAttribute("data-contenido")];
            if (html == null || html === "") return;
            m.innerHTML = SOLO_TEXTO.test(m.tagName) ? comoLineas(html) : html;
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

    // Enlaces que acepta el menú: páginas del sitio (pagina.html, con ?... o #...
    // opcionales), direcciones https:// o mailto:. Cualquier otro (ej: javascript:) se omite.
    function enlaceMenuValido(enlace) {
        return /^(https?:\/\/|mailto:)\S+$/i.test(enlace) ||
            /^[\w.\/-]+\.html?([?#]\S*)?$/i.test(enlace);
    }

    // Página a la que apunta un enlace del sitio ("elpunto.html#x" -> "elpunto.html").
    function paginaDeEnlace(enlace) {
        if (/^(https?:|mailto:)/i.test(enlace)) return "";
        return enlace.split(/[?#]/)[0].split("/").pop().toLowerCase();
    }

    // Cambia las opciones de cada lista <ul data-menu> por las de la tabla "menu"
    // (visibles, en su orden). Cada opción copia las clases del primer enlace que
    // trae el HTML, para verse igual. Si la tabla está vacía o no se puede leer,
    // queda el menú del HTML.
    function aplicarMenu(cliente) {
        var listas = document.querySelectorAll("[data-menu]");
        if (listas.length === 0) return Promise.resolve();

        return cliente
            .from("menu")
            .select("etiqueta, enlace, nueva_pestana")
            .eq("visible", true)
            .order("orden", { ascending: true })
            .order("id", { ascending: true })
            .then(function (respuesta) {
                if (!respuesta || respuesta.error || !respuesta.data) return;
                var opciones = respuesta.data.filter(function (o) {
                    return o.etiqueta && o.enlace && enlaceMenuValido(String(o.enlace).trim());
                });
                if (opciones.length === 0) return;
                var actual = paginaActual();

                Array.prototype.forEach.call(listas, function (lista) {
                    var modelo = lista.querySelector("a");
                    var clases = modelo ? modelo.className : "nav-link link";
                    var items = opciones.map(function (o) {
                        var enlace = String(o.enlace).trim();
                        var li = document.createElement("li");
                        li.className = "nav-item";
                        var a = document.createElement("a");
                        a.className = clases;
                        a.href = enlace;
                        a.textContent = o.etiqueta;
                        if (o.nueva_pestana) {
                            a.target = "_blank";
                            a.rel = "noopener";
                        }
                        if (paginaDeEnlace(enlace) === actual) a.setAttribute("aria-current", "page");
                        li.appendChild(a);
                        return li;
                    });
                    lista.replaceChildren.apply(lista, items);
                });
            });
    }

    // ==================== ESTILOS DE TÍTULOS ====================
    // Grupos de títulos y las clases que usan las páginas para cada uno. La clave es
    // la de la tabla "estilos_titulos". Si un elemento está en dos grupos, manda el
    // primero de la lista.
    var GRUPOS_ESTILO = [
        { clave: "titulos", selector: ".mbr-section-title, .titulo-cci-al, .ep-titulo, .ep-articulo-titulo, .ct-titulo, .anuncios-titulo" },
        { clave: "subtitulos", selector: ".mbr-section-subtitle, .item-subtitle, .rd-grupo-titulo" },
        { clave: "tarjetas", selector: ".card-title, .item-title, .ep-tarjeta-titulo, .ct-producto-nombre, .rd-nombre" }
    ];

    // Tipos de letra que ofrece el panel (la misma lista que FUENTES_TITULOS en admin.html).
    // "google": familia y grosores para Google Fonts; sin "google" es una letra del sistema.
    var FUENTES = {
        "Inter": { google: "Inter:wght@400;600;700", respaldo: "sans-serif" },
        "Jost": { google: "Jost:wght@400;600;700", respaldo: "sans-serif" },
        "Montserrat": { google: "Montserrat:wght@400;600;700", respaldo: "sans-serif" },
        "Poppins": { google: "Poppins:wght@400;600;700", respaldo: "sans-serif" },
        "Roboto": { google: "Roboto:wght@400;500;700", respaldo: "sans-serif" },
        "Open Sans": { google: "Open+Sans:wght@400;600;700", respaldo: "sans-serif" },
        "Lato": { google: "Lato:wght@400;700", respaldo: "sans-serif" },
        "Raleway": { google: "Raleway:wght@400;600;700", respaldo: "sans-serif" },
        "Nunito": { google: "Nunito:wght@400;600;700", respaldo: "sans-serif" },
        "Work Sans": { google: "Work+Sans:wght@400;600;700", respaldo: "sans-serif" },
        "Oswald": { google: "Oswald:wght@400;600;700", respaldo: "sans-serif" },
        "Playfair Display": { google: "Playfair+Display:wght@400;700", respaldo: "serif" },
        "Merriweather": { google: "Merriweather:wght@400;700", respaldo: "serif" },
        "Lora": { google: "Lora:wght@400;700", respaldo: "serif" },
        "Arial": { respaldo: "sans-serif" },
        "Verdana": { respaldo: "sans-serif" },
        "Georgia": { respaldo: "serif" }
    };
    var ESPERA_FUENTE = 1500; // máximo que se espera una letra de Google antes de mostrar la página

    // Los mismos formatos que exige la tabla: así nada raro llega al CSS.
    var FUENTE_VALIDA = /^[A-Za-z0-9 ]{1,60}$/;
    var COLOR_VALIDO = /^#[0-9A-Fa-f]{6}$/;

    function consultarEstilos(cliente) {
        return cliente
            .from("estilos_titulos")
            .select("clave, fuente, tamano, color")
            .then(function (respuesta) {
                return respuesta && !respuesta.error ? respuesta.data : null;
            });
    }

    function familiaCss(nombre) {
        var fuente = FUENTES[nombre] || {};
        return '"' + nombre + '", ' + (fuente.respaldo || "sans-serif");
    }

    // Carga una letra de Google Fonts y espera a que esté lista (o ESPERA_FUENTE),
    // para que los títulos no aparezcan primero con otra letra.
    function cargarFuente(nombre) {
        var fuente = FUENTES[nombre];
        if (!fuente || !fuente.google) return Promise.resolve();
        return new Promise(function (resolver) {
            var enlace = document.createElement("link");
            enlace.rel = "stylesheet";
            enlace.href = "https://fonts.googleapis.com/css2?family=" + fuente.google + "&display=swap";
            enlace.onload = function () {
                if (!document.fonts || !document.fonts.load) return resolver();
                Promise.all([
                    document.fonts.load('400 1em "' + nombre + '"'),
                    document.fonts.load('700 1em "' + nombre + '"')
                ]).then(resolver, resolver);
            };
            enlace.onerror = resolver;
            document.head.appendChild(enlace);
            setTimeout(resolver, ESPERA_FUENTE);
        });
    }

    // Reglas de letra y color. Van con !important y con :not(#_) (que suma peso de id)
    // para ganarle a los estilos de cada página. Los textos con color propio puesto en
    // "Contenido de secciones" (un <span> con color dentro del título) lo conservan.
    // Se escriben del último grupo al primero: si un elemento está en dos, gana el primero.
    function reglasDeEstilos(grupos) {
        var reglas = [
            // Tamaño: lo calcula escalarTamanos() para cada elemento (ver más abajo).
            "html:not(.estilos-midiendo) [data-estilo-tam]:not(#_){font-size:var(--estilo-tam)!important}",
            "html:not(.estilos-midiendo) [data-estilo-alto]:not(#_){line-height:var(--estilo-alto)!important}"
        ];
        grupos.slice().reverse().forEach(function (g) {
            var selector = ":is(" + g.selector + "):not(#_)";
            var declaraciones = [];
            if (g.fuente) declaraciones.push("font-family:" + familiaCss(g.fuente) + "!important");
            if (g.color) declaraciones.push("color:" + g.color + "!important");
            if (declaraciones.length) reglas.push(selector + "{" + declaraciones.join(";") + "}");
            // Los enlaces dentro del título (ej: el título de un artículo) toman su color.
            if (g.color) reglas.push(selector + ' a:not([style*="color"]){color:inherit!important}');
        });
        return reglas.join("\n");
    }

    // ---------- Tamaño ----------
    // El tamaño es un porcentaje del original de cada título, que cambia según la página,
    // la clase y el ancho de la pantalla. Por eso se mide el tamaño real de cada elemento
    // (con las reglas de tamaño apagadas: clase "estilos-midiendo") y se le pone el
    // tamaño escalado en la variable --estilo-tam. Se vuelve a medir al cambiar el ancho
    // de la ventana y cuando aparecen títulos nuevos (tarjetas que se arman después).

    function buscarEn(raiz, selector) {
        var lista = raiz.querySelectorAll ? Array.prototype.slice.call(raiz.querySelectorAll(selector)) : [];
        if (raiz.matches && raiz.matches(selector)) lista.unshift(raiz);
        return lista;
    }

    // Elementos de "raiz" con tamaño a escalar, cada uno con el factor de su grupo.
    function elementosAEscalar(grupos, raiz) {
        var vistos = [];
        var lista = [];
        grupos.forEach(function (g) {
            buscarEn(raiz, g.selector).forEach(function (el) {
                if (vistos.indexOf(el) !== -1) return;
                vistos.push(el);
                if (g.factor) lista.push({ el: el, factor: g.factor });
            });
        });
        return lista;
    }

    function escalarTamanos(lista) {
        if (lista.length === 0) return;
        var raiz = document.documentElement;
        // Primero se leen todos los tamaños originales y después se escriben,
        // para que el navegador recalcule los estilos una sola vez.
        raiz.classList.add("estilos-midiendo");
        var medidas = lista.map(function (x) {
            var calculado = getComputedStyle(x.el);
            return {
                tamano: parseFloat(calculado.fontSize),
                alto: /px$/.test(calculado.lineHeight) ? parseFloat(calculado.lineHeight) : null
            };
        });
        raiz.classList.remove("estilos-midiendo");
        lista.forEach(function (x, i) {
            var m = medidas[i];
            if (!(m.tamano > 0)) return;
            x.el.style.setProperty("--estilo-tam", (m.tamano * x.factor).toFixed(2) + "px");
            x.el.setAttribute("data-estilo-tam", "");
            // El alto de línea también, por si la página lo fija en px (ej: en celulares).
            if (m.alto) {
                x.el.style.setProperty("--estilo-alto", (m.alto * x.factor).toFixed(2) + "px");
                x.el.setAttribute("data-estilo-alto", "");
            } else {
                x.el.style.removeProperty("--estilo-alto");
                x.el.removeAttribute("data-estilo-alto");
            }
        });
    }

    function vigilarTamanos(grupos) {
        escalarTamanos(elementosAEscalar(grupos, document));

        var espera = null;
        window.addEventListener("resize", function () {
            clearTimeout(espera);
            espera = setTimeout(function () { escalarTamanos(elementosAEscalar(grupos, document)); }, 150);
        });

        if (!window.MutationObserver || !document.body) return;
        new MutationObserver(function (cambios) {
            var lista = [];
            cambios.forEach(function (cambio) {
                Array.prototype.forEach.call(cambio.addedNodes, function (nodo) {
                    if (nodo.nodeType === 1) lista = lista.concat(elementosAEscalar(grupos, nodo));
                });
            });
            escalarTamanos(lista);
        }).observe(document.body, { childList: true, subtree: true });
    }

    // Aplica los estilos guardados. Devuelve una promesa que termina cuando las letras
    // elegidas están cargadas (o pasó ESPERA_FUENTE). Sin estilos guardados no hace nada.
    function aplicarEstilos(filas) {
        if (!filas || filas.length === 0) return Promise.resolve();
        var porClave = {};
        filas.forEach(function (fila) { porClave[fila.clave] = fila; });

        var grupos = GRUPOS_ESTILO.map(function (g) {
            var fila = porClave[g.clave] || {};
            var tamano = Number(fila.tamano);
            return {
                selector: g.selector,
                fuente: FUENTE_VALIDA.test(fila.fuente || "") ? fila.fuente : null,
                color: COLOR_VALIDO.test(fila.color || "") ? fila.color : null,
                factor: tamano >= 50 && tamano <= 200 && tamano !== 100 ? tamano / 100 : null
            };
        });
        if (!grupos.some(function (g) { return g.fuente || g.color || g.factor; })) return Promise.resolve();

        var hoja = document.createElement("style");
        hoja.id = "estilos-titulos";
        hoja.textContent = reglasDeEstilos(grupos);
        document.head.appendChild(hoja);

        if (grupos.some(function (g) { return g.factor; })) vigilarTamanos(grupos);

        var fuentes = [];
        grupos.forEach(function (g) {
            if (g.fuente && fuentes.indexOf(g.fuente) === -1) fuentes.push(g.fuente);
        });
        return Promise.all(fuentes.map(cargarFuente));
    }

    function ignorarError() {
        // Ante cualquier error se deja esa parte de la página tal como está en el HTML.
    }

    function aplicarSecciones() {
        obtenerClienteSupabase()
            .then(function (cliente) {
                // Las consultas (secciones, textos, imágenes, menú y estilos) van en paralelo.
                var secciones = cliente
                    .from("informacion_general")
                    .select("clave, visible, orden")
                    .eq("pagina", paginaActual())
                    .then(function (respuesta) {
                        if (respuesta && !respuesta.error && respuesta.data) {
                            aplicar(respuesta.data);
                            ordenar(respuesta.data);
                        }
                    })
                    .catch(ignorarError);
                var contenido = consultarContenido(cliente).catch(ignorarError);
                var estilos = consultarEstilos(cliente).catch(ignorarError);
                var pagina = Promise.all([
                    // Los textos se ponen después de quitar los bloques ocultos.
                    Promise.all([secciones, contenido]).then(function (resultados) {
                        ponerContenido(resultados[1]);
                    }),
                    aplicarImagenes(cliente).catch(ignorarError),
                    aplicarMenu(cliente).catch(ignorarError)
                ]).catch(ignorarError);
                // Los estilos de títulos van al final, con los textos ya puestos,
                // porque el tamaño se mide sobre los títulos definitivos.
                return Promise.all([pagina, estilos]).then(function (resultados) {
                    return aplicarEstilos(resultados[1]);
                });
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
