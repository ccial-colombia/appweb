// Equipados > 3. Recursos descargables: muestra los PDF de la tabla "descargables"
// de Supabase, agrupados por categoría. Se administran desde admin.html, en la
// pestaña "Recursos descargables".
// Requiere assets/js/secciones.js (obtenerClienteSupabase).
(function () {
    "use strict";

    var CORREO = "comunicacionesccialcol@gmail.com";

    // Ícono que reemplaza la portada cuando el recurso no tiene una.
    var ICONO_PDF =
        '<svg viewBox="0 0 48 60" aria-hidden="true" focusable="false">' +
        '<path d="M6 2h26l14 14v38a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V6a4 4 0 0 1 4-4z" fill="#ffffff" stroke="currentColor" stroke-width="2.5"/>' +
        '<path d="M32 2v10a4 4 0 0 0 4 4h10" fill="none" stroke="currentColor" stroke-width="2.5"/>' +
        '<rect x="7" y="32" width="34" height="14" rx="3" fill="currentColor"/>' +
        '<text x="24" y="43" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="10" font-weight="700" fill="#ffffff">PDF</text>' +
        "</svg>";

    function crear(etiqueta, clase, texto) {
        var el = document.createElement(etiqueta);
        if (clase) el.className = clase;
        if (texto != null) el.textContent = texto;
        return el;
    }

    // 2516582 -> "2,4 MB"; 81920 -> "80 KB".
    function formatoTamano(bytes) {
        if (bytes == null || isNaN(bytes)) return "";
        var mb = bytes / (1024 * 1024);
        if (mb >= 1) return mb.toLocaleString("es-CO", { maximumFractionDigits: 1 }) + " MB";
        return Math.max(1, Math.round(bytes / 1024)) + " KB";
    }

    // Nombre con el que se guarda el archivo: el título sin tildes ni símbolos.
    function nombreArchivo(titulo) {
        var base = String(titulo || "recurso")
            .normalize("NFD").replace(/[̀-ͯ]/g, "")
            .replace(/[^A-Za-z0-9 ._-]+/g, " ")
            .replace(/\s+/g, " ").trim();
        return (base || "recurso") + ".pdf";
    }

    // Los PDF subidos desde el panel están en Supabase Storage, en otro dominio,
    // donde el navegador ignora el atributo "download": ahí se pide la descarga
    // con el parámetro ?download=nombre. Los archivos del propio sitio usan "download".
    function prepararDescarga(enlace, recurso) {
        var url = recurso.archivo_url;
        var nombre = nombreArchivo(recurso.titulo);
        if (url.indexOf("/storage/v1/object/public/") !== -1) {
            enlace.href = url + (url.indexOf("?") === -1 ? "?" : "&") + "download=" + encodeURIComponent(nombre);
        } else {
            enlace.href = url;
            enlace.setAttribute("download", nombre);
        }
    }

    function miniatura(recurso) {
        var marco = crear("div", "rd-miniatura");
        if (recurso.imagen_url) {
            var img = crear("img");
            img.src = recurso.imagen_url;
            img.alt = "";
            img.loading = "lazy";
            img.decoding = "async";
            // Si la portada no carga, queda el ícono de PDF.
            img.addEventListener("error", function () {
                marco.classList.add("sin-portada");
                marco.innerHTML = ICONO_PDF;
            });
            marco.appendChild(img);
        } else {
            marco.classList.add("sin-portada");
            marco.innerHTML = ICONO_PDF;
        }
        return marco;
    }

    function tarjeta(recurso) {
        var columna = crear("div", "col-12 col-lg-6");
        var articulo = crear("article", "rd-recurso");

        articulo.appendChild(miniatura(recurso));

        var cuerpo = crear("div", "rd-cuerpo");
        cuerpo.appendChild(crear("h5", "rd-nombre", recurso.titulo));
        if (recurso.descripcion) {
            cuerpo.appendChild(crear("p", "rd-desc", recurso.descripcion));
        }
        var tamano = formatoTamano(recurso.tamano_bytes);
        cuerpo.appendChild(crear("p", "rd-meta", "PDF" + (tamano ? " · " + tamano : "")));

        var acciones = crear("div", "rd-acciones");
        var descargar = crear("a", "btn btn-primary rd-btn", "Descargar");
        prepararDescarga(descargar, recurso);
        descargar.setAttribute("aria-label", "Descargar " + recurso.titulo + " (PDF)");
        acciones.appendChild(descargar);

        var ver = crear("a", "btn btn-primary-outline rd-btn", "Ver");
        ver.href = recurso.archivo_url;
        ver.target = "_blank";
        ver.rel = "noopener";
        ver.setAttribute("aria-label", "Ver " + recurso.titulo + " en una pestaña nueva");
        acciones.appendChild(ver);

        cuerpo.appendChild(acciones);
        articulo.appendChild(cuerpo);
        columna.appendChild(articulo);
        return columna;
    }

    function mostrarError(estado) {
        var enlace = crear("a", "text-primary", CORREO);
        enlace.href = "mailto:" + CORREO + "?subject=" + encodeURIComponent("Recursos descargables");
        estado.textContent = "No pudimos cargar los recursos en este momento. Escríbenos a ";
        estado.appendChild(enlace);
        estado.appendChild(document.createTextNode("."));
        estado.hidden = false;
    }

    async function cargarDescargables() {
        var seccion = document.getElementById("descargables");
        var estado = document.getElementById("rd-estado");
        if (!seccion || !estado) return; // sección deshabilitada desde el panel

        try {
            var cliente = await window.obtenerClienteSupabase();
            var respuesta = await cliente
                .from("descargables")
                .select("id, categoria, titulo, descripcion, archivo_url, tamano_bytes, imagen_url")
                .eq("visible", true)
                .order("orden", { ascending: true })
                .order("id", { ascending: true });
            if (respuesta.error) throw respuesta.error;

            var recursos = (respuesta.data || []).filter(function (r) { return r.archivo_url; });
            var mostrados = 0;
            Array.prototype.forEach.call(seccion.querySelectorAll(".rd-grupo[data-categoria]"), function (grupo) {
                var propios = recursos.filter(function (r) { return r.categoria === grupo.getAttribute("data-categoria"); });
                var lista = grupo.querySelector(".rd-lista");
                if (lista) lista.replaceChildren.apply(lista, propios.map(tarjeta));
                grupo.hidden = propios.length === 0;
                mostrados += propios.length;
            });

            if (mostrados === 0) {
                estado.textContent = "Pronto tendremos recursos disponibles para descargar.";
                estado.hidden = false;
                return;
            }
            estado.hidden = true;
        } catch (error) {
            console.error("Recursos descargables: no se pudieron cargar.", error);
            mostrarError(estado);
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", cargarDescargables);
    } else {
        cargarDescargables();
    }
})();
