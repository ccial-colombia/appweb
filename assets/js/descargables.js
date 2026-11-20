// Equipados > 3. Recursos descargables: muestra los PDF de la tabla "descargables"
// de Supabase, agrupados por categoría. Se administran desde admin.html, en la
// pestaña "Recursos descargables".
// Requiere assets/js/secciones.js (obtenerClienteSupabase).
//
// Los PDF están en el bucket privado "descargables" de Supabase: no tienen una URL
// fija que se pueda compartir. Al pulsar "Ver" o "Descargar" se pide un enlace
// firmado que vence a los pocos minutos (VIGENCIA_ENLACE): si alguien copia ese
// enlace y lo comparte, deja de abrir enseguida y hay que entrar por la página para
// ver el PDF. Ver supabase/recursos_descargables.sql.
(function () {
    "use strict";

    var CORREO = "comunicacionesccialcol@gmail.com";
    var BUCKET = "descargables";

    // Segundos que dura cada enlace firmado. Alcanza para que el PDF termine de
    // cargar aun con conexión lenta; después el enlace ya no abre.
    var VIGENCIA_ENLACE = 120;

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

    // Ruta del PDF dentro del bucket, a partir de la URL que guarda el panel:
    //   ".../storage/v1/object/public/descargables/descargables/123-x.pdf"
    //   -> "descargables/123-x.pdf"
    // null si el PDF no está en el bucket (ej: un archivo del propio sitio).
    function rutaEnBucket(url) {
        var marca = "/storage/v1/object/";
        var i = url.indexOf(marca);
        if (i === -1) return null;
        // "public/descargables/descargables/123-x.pdf" (o "sign/..." en vez de "public/...")
        var partes = url.slice(i + marca.length).split(/[?#]/)[0].split("/");
        if (partes.length < 3 || partes[1] !== BUCKET) return null;
        var ruta = partes.slice(2).join("/");
        try { return decodeURIComponent(ruta); } catch (e) { return ruta; }
    }

    // Pide a Supabase un enlace temporal al PDF. Con "nombre" el enlace descarga
    // el archivo con ese nombre en vez de abrirlo.
    async function enlaceFirmado(ruta, nombre) {
        var cliente = await window.obtenerClienteSupabase();
        var respuesta = await cliente.storage.from(BUCKET)
            .createSignedUrl(ruta, VIGENCIA_ENLACE, nombre ? { download: nombre } : undefined);
        if (respuesta.error || !respuesta.data || !respuesta.data.signedUrl) {
            throw respuesta.error || new Error("Supabase no devolvió el enlace del PDF.");
        }
        return respuesta.data.signedUrl;
    }

    // "Ver": abre el PDF en una pestaña nueva. La pestaña se abre en el mismo clic,
    // antes de esperar el enlace (si se abriera después, el navegador la bloquearía
    // como ventana emergente), y luego se lleva al enlace firmado.
    async function verPdf(ruta) {
        var pestana = window.open("", "_blank");
        if (pestana) {
            try {
                pestana.document.title = "Abriendo PDF…";
                pestana.document.body.textContent = "Abriendo el PDF…";
            } catch (e) { /* solo es un aviso mientras carga */ }
        }
        var url;
        try {
            url = await enlaceFirmado(ruta);
        } catch (error) {
            if (pestana) pestana.close();
            throw error;
        }
        if (pestana) {
            pestana.opener = null;
            pestana.location.replace(url);
        } else {
            // Ventanas emergentes bloqueadas: se abre en esta misma pestaña.
            window.location.href = url;
        }
    }

    // "Descargar": el enlace firmado responde como descarga, así que la página no se va.
    async function descargarPdf(ruta, recurso) {
        window.location.href = await enlaceFirmado(ruta, nombreArchivo(recurso.titulo));
    }

    // Mensaje de error debajo de los botones de la tarjeta (vacío lo quita).
    function avisar(acciones, texto) {
        var aviso = acciones.querySelector(".rd-aviso");
        if (!texto) {
            if (aviso) aviso.remove();
            return;
        }
        if (!aviso) {
            aviso = crear("p", "rd-aviso");
            aviso.setAttribute("role", "alert");
            acciones.appendChild(aviso);
        }
        aviso.textContent = texto;
    }

    // Botón que pide el enlace firmado al pulsarlo. Es un botón y no un enlace para
    // que no haya una dirección que copiar con "Copiar enlace".
    function botonPdf(texto, clase, etiqueta, alPulsar) {
        var boton = crear("button", "btn " + clase + " rd-btn", texto);
        boton.type = "button";
        boton.setAttribute("aria-label", etiqueta);
        boton.addEventListener("click", function () {
            if (boton.disabled) return;
            var acciones = boton.parentNode;
            boton.disabled = true;
            avisar(acciones, "");
            alPulsar()
                .catch(function (error) {
                    console.error("Recursos descargables: no se pudo abrir el PDF.", error);
                    avisar(acciones, "No se pudo abrir el PDF. Recarga la página e intenta de nuevo.");
                })
                .then(function () { boton.disabled = false; });
        });
        return boton;
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
        var ruta = rutaEnBucket(recurso.archivo_url);
        if (ruta) {
            acciones.appendChild(botonPdf("Descargar", "btn-primary", "Descargar " + recurso.titulo + " (PDF)",
                function () { return descargarPdf(ruta, recurso); }));
            acciones.appendChild(botonPdf("Ver", "btn-primary-outline", "Ver " + recurso.titulo + " en una pestaña nueva",
                function () { return verPdf(ruta); }));
        } else {
            // PDF guardado en el propio sitio (no en el bucket): enlace directo, sin protección.
            var descargar = crear("a", "btn btn-primary rd-btn", "Descargar");
            descargar.href = recurso.archivo_url;
            descargar.setAttribute("download", nombreArchivo(recurso.titulo));
            descargar.setAttribute("aria-label", "Descargar " + recurso.titulo + " (PDF)");
            acciones.appendChild(descargar);

            var ver = crear("a", "btn btn-primary-outline rd-btn", "Ver");
            ver.href = recurso.archivo_url;
            ver.target = "_blank";
            ver.rel = "noopener";
            ver.setAttribute("aria-label", "Ver " + recurso.titulo + " en una pestaña nueva");
            acciones.appendChild(ver);
        }

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
