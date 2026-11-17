// Carruseles con los anuncios vigentes de la tabla "anuncios" de Supabase. Se administran
// desde admin.html, en la pestaña "Anuncios". Cada carrusel lleva data-anuncios:
//   data-anuncios="portada" (index.html): a la imagen de bienvenida (index.portada), que es
//       la primera, le suma los anuncios. Sin anuncios vigentes queda solo la imagen.
//   data-anuncios="solo" (inicio.html, sección "Anuncios" al final): solo los anuncios.
//       Sin anuncios vigentes la sección no se muestra.
// Requiere assets/js/secciones.js (obtenerClienteSupabase) y Bootstrap (carrusel).
(function () {
    "use strict";

    var INTERVALO = 6000; // milisegundos que se muestra cada imagen

    var ICONO_PAUSA = '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">' +
        '<rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>';
    var ICONO_REANUDAR = '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">' +
        '<path d="M8 5.5v13a1 1 0 0 0 1.5.86l11-6.5a1 1 0 0 0 0-1.72l-11-6.5A1 1 0 0 0 8 5.5z"/></svg>';

    // Fecha de hoy en Colombia (AAAA-MM-DD), la misma que usa la base de datos.
    function hoyEnColombia() {
        try {
            return new Intl.DateTimeFormat("en-CA", {
                timeZone: "America/Bogota", year: "numeric", month: "2-digit", day: "2-digit"
            }).format(new Date());
        } catch (e) {
            var d = new Date();
            return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" +
                String(d.getDate()).padStart(2, "0");
        }
    }

    function enlaceValido(url) {
        return /^(https?:\/\/|mailto:)/i.test(String(url || "").trim());
    }

    function diapositiva(anuncio, activa) {
        var item = document.createElement("div");
        item.className = "carousel-item" + (activa ? " active" : "");

        var img = document.createElement("img");
        img.className = "d-block w-100";
        img.src = anuncio.imagen_url;
        img.alt = anuncio.titulo || "Anuncio";
        img.decoding = "async";

        if (enlaceValido(anuncio.enlace)) {
            var enlace = document.createElement("a");
            enlace.className = "carrusel-enlace";
            enlace.href = anuncio.enlace.trim();
            enlace.target = "_blank";
            enlace.rel = "noopener";
            enlace.setAttribute("aria-label", (anuncio.titulo || "Anuncio") + " (se abre en una pestaña nueva)");
            enlace.appendChild(img);
            item.appendChild(enlace);
        } else {
            item.appendChild(img);
        }
        return item;
    }

    function indicador(carrusel, indice, etiqueta) {
        var boton = document.createElement("button");
        boton.type = "button";
        boton.setAttribute("data-bs-target", "#" + carrusel.id);
        boton.setAttribute("data-bs-slide-to", String(indice));
        boton.setAttribute("aria-label", etiqueta);
        if (indice === 0) {
            boton.className = "active";
            boton.setAttribute("aria-current", "true");
        }
        return boton;
    }

    // Todas las imágenes usan el marco de la imagen de bienvenida (aunque se cambie
    // desde el panel): así el carrusel no cambia de alto al pasar de una a otra.
    // Sin imagen de bienvenida (inicio.html) se usa el formato recomendado, 1600 × 753.
    function igualarProporcion(carrusel, portada) {
        function aplicar() {
            if (portada.naturalWidth && portada.naturalHeight) {
                carrusel.style.setProperty("--proporcion-portada", portada.naturalWidth + " / " + portada.naturalHeight);
            }
        }
        portada.addEventListener("load", aplicar);
        if (portada.complete) aplicar();
    }

    // Etiqueta de cada diapositiva para los lectores de pantalla y los puntos.
    function etiquetaDiapositiva(conPortada, anuncios, i) {
        if (conPortada && i === 0) return "Imagen de bienvenida";
        var n = conPortada ? i : i + 1;
        return "Anuncio " + n + ": " + (anuncios[n - 1].titulo || "");
    }

    // Con una sola imagen no hay flechas, puntos ni avance automático.
    function activarCarrusel(carrusel, anuncios, conPortada) {
        var items = carrusel.querySelectorAll(".carousel-item");
        var indicadores = carrusel.querySelector(".carousel-indicators");

        carrusel.classList.add("con-anuncios");
        if (conPortada) igualarProporcion(carrusel, items[0].querySelector("img"));
        if (items.length < 2) return;

        Array.prototype.forEach.call(items, function (item, i) {
            item.setAttribute("role", "group");
            item.setAttribute("aria-roledescription", "diapositiva");
            item.setAttribute("aria-label", (i + 1) + " de " + items.length);
            indicadores.appendChild(indicador(carrusel, i, etiquetaDiapositiva(conPortada, anuncios, i)));
        });
        indicadores.hidden = false;
        Array.prototype.forEach.call(carrusel.querySelectorAll(".carousel-control-prev, .carousel-control-next"), function (b) {
            b.hidden = false;
        });

        // El avance automático lo maneja este script (pause: false): se detiene con el
        // botón de pausa, mientras el mouse o el foco están sobre el carrusel, y no
        // arranca solo si el dispositivo pide reducir el movimiento.
        var carruselBs = bootstrap.Carousel.getInstance(carrusel) ||
            new bootstrap.Carousel(carrusel, { interval: INTERVALO, pause: false, wrap: true, keyboard: true, touch: true });

        var botonPausa = carrusel.querySelector(".carrusel-pausa");
        var reducirMovimiento = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
        var reproduciendo = !reducirMovimiento;
        var mouseEncima = false;
        var focoDentro = false;

        function actualizarAvance() {
            if (reproduciendo && !mouseEncima && !focoDentro) carruselBs.cycle();
            else carruselBs.pause();
        }

        function pintarBotonPausa() {
            botonPausa.innerHTML = reproduciendo ? ICONO_PAUSA : ICONO_REANUDAR;
            botonPausa.setAttribute("aria-label", reproduciendo ? "Pausar el carrusel" : "Reanudar el carrusel");
        }

        botonPausa.addEventListener("click", function () {
            reproduciendo = !reproduciendo;
            pintarBotonPausa();
            actualizarAvance();
        });
        carrusel.addEventListener("pointerenter", function (e) {
            if (e.pointerType === "mouse") { mouseEncima = true; actualizarAvance(); }
        });
        carrusel.addEventListener("pointerleave", function (e) {
            if (e.pointerType === "mouse") { mouseEncima = false; actualizarAvance(); }
        });
        carrusel.addEventListener("focusin", function () { focoDentro = true; actualizarAvance(); });
        carrusel.addEventListener("focusout", function (e) {
            if (!carrusel.contains(e.relatedTarget)) { focoDentro = false; actualizarAvance(); }
        });

        botonPausa.hidden = false;
        pintarBotonPausa();
        actualizarAvance();
    }

    // Pone los anuncios en un carrusel. Devuelve false si no hay nada que mostrar.
    function llenarCarrusel(carrusel, anuncios) {
        var conPortada = carrusel.getAttribute("data-anuncios") !== "solo";
        if (anuncios.length === 0) return false;

        var interior = carrusel.querySelector(".carousel-inner");
        anuncios.forEach(function (anuncio, i) {
            interior.appendChild(diapositiva(anuncio, !conPortada && i === 0));
        });
        activarCarrusel(carrusel, anuncios, conPortada);
        return true;
    }

    // Carruseles "solo" (sin imagen de bienvenida): la sección que los contiene se muestra
    // únicamente si hay anuncios.
    function mostrarSeccion(carrusel) {
        var seccion = carrusel.closest("[data-anuncios-seccion]");
        if (seccion) seccion.hidden = false;
    }

    async function cargarAnuncios() {
        var carruseles = document.querySelectorAll("[data-anuncios]");
        if (carruseles.length === 0 || !window.bootstrap || !window.bootstrap.Carousel) return;

        var anuncios = [];
        try {
            var cliente = await window.obtenerClienteSupabase();
            var hoy = hoyEnColombia();
            // La base ya entrega solo los vigentes; el filtro se repite por si el
            // navegador tiene abierta la sesión del panel (que ve todos).
            var respuesta = await cliente
                .from("anuncios")
                .select("id, imagen_url, titulo, enlace")
                .eq("visible", true)
                .lte("fecha_inicio", hoy)
                .gte("fecha_fin", hoy)
                .order("orden", { ascending: true })
                .order("id", { ascending: true });
            if (respuesta.error) throw respuesta.error;
            anuncios = (respuesta.data || []).filter(function (a) { return a.imagen_url; });
        } catch (error) {
            // Sin anuncios: index.html muestra solo la imagen de bienvenida y
            // la sección de anuncios de inicio.html queda oculta.
            console.error("Anuncios: no se pudieron cargar.", error);
            return;
        }

        Array.prototype.forEach.call(carruseles, function (carrusel) {
            if (llenarCarrusel(carrusel, anuncios) && carrusel.getAttribute("data-anuncios") === "solo") {
                mostrarSeccion(carrusel);
            }
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", cargarAnuncios);
    } else {
        cargarAnuncios();
    }
})();
