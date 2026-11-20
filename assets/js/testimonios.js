// Testimonios de la tabla "testimonios" de Supabase, con el mismo diseño de los
// artículos de El Punto (estilos de assets/css/elpunto.css). Se administran desde
// admin.html, en la pestaña "Testimonios".
//   comunidad.html  -> tarjetas de los testimonios, en su orden (sección Testimonios)
//   testimonio.html -> un testimonio completo (testimonio.html?id=...)
// Requiere assets/js/secciones.js (obtenerClienteSupabase).
(function () {
    "use strict";

    var LARGO_RESUMEN = 220; // caracteres del resumen en cada tarjeta

    function crear(etiqueta, clase, texto) {
        var el = document.createElement(etiqueta);
        if (clase) el.className = clase;
        if (texto != null) el.textContent = texto;
        return el;
    }

    // Texto sin formato del testimonio, para el resumen de la tarjeta. Se lee en un
    // documento aparte (DOMParser) para que no se cargue nada del contenido.
    function textoPlano(html) {
        // Un espacio al cerrar cada párrafo, título o elemento de lista, para que no se peguen las palabras.
        var conEspacios = String(html || "").replace(/<\/(p|h[1-6]|li|blockquote|pre|div)>|<br\s*\/?>/gi, " $&");
        var documento = new DOMParser().parseFromString(conEspacios, "text/html");
        return (documento.body.textContent || "").replace(/\s+/g, " ").trim();
    }

    // Corta el texto en la última palabra completa antes del límite.
    function resumen(html) {
        var texto = textoPlano(html);
        if (texto.length <= LARGO_RESUMEN) return texto;
        var corte = texto.lastIndexOf(" ", LARGO_RESUMEN);
        if (corte < LARGO_RESUMEN * 0.6) corte = LARGO_RESUMEN;
        return texto.slice(0, corte).replace(/[\s.,;:¡!¿?-]+$/, "") + "…";
    }

    function enlaceTestimonio(id) {
        return "testimonio.html?id=" + encodeURIComponent(id);
    }

    function fotoDe(testimonio, grande) {
        var foto = crear("img", "ep-autor-foto");
        foto.src = testimonio.foto_url;
        foto.alt = "Foto de " + testimonio.nombre;
        foto.decoding = "async";
        if (!grande) foto.loading = "lazy";
        return foto;
    }

    // Tarjeta: comillas, resumen del testimonio, enlace para leerlo completo y,
    // al pie, quién lo da (foto, nombre y rol), como el autor de un artículo.
    function tarjeta(testimonio) {
        var columna = crear("div", "col-12 col-md-6 col-lg-4");
        var caja = crear("article", "ep-tarjeta tt-tarjeta");
        caja.appendChild(crear("span", "tt-comillas", "“")).setAttribute("aria-hidden", "true");

        var texto = resumen(testimonio.mensaje);
        if (texto) caja.appendChild(crear("p", "ep-resumen tt-resumen", texto));

        var leer = crear("a", "ep-leer", "Leer testimonio");
        leer.href = enlaceTestimonio(testimonio.id);
        leer.setAttribute("aria-label", "Leer el testimonio de " + testimonio.nombre);
        caja.appendChild(leer);

        var autor = crear("div", "ep-autor");
        if (testimonio.foto_url) autor.appendChild(fotoDe(testimonio, false));
        var datos = crear("div", "ep-autor-datos");
        datos.appendChild(crear("h3", "ep-autor-nombre tt-nombre-tarjeta", testimonio.nombre));
        if (testimonio.rol) datos.appendChild(crear("span", "ep-autor-rol", testimonio.rol));
        autor.appendChild(datos);
        caja.appendChild(autor);

        columna.appendChild(caja);
        return columna;
    }

    async function cargarLista(lista, estado) {
        try {
            var cliente = await window.obtenerClienteSupabase();
            var respuesta = await cliente
                .from("testimonios")
                .select("id, nombre, rol, mensaje, foto_url")
                .eq("visible", true)
                .order("orden", { ascending: true })
                .order("id", { ascending: true });
            if (respuesta.error) throw respuesta.error;

            if (!respuesta.data || respuesta.data.length === 0) {
                estado.textContent = "Aún no hay testimonios registrados.";
                return;
            }
            lista.replaceChildren.apply(lista, respuesta.data.map(tarjeta));
            estado.hidden = true;
        } catch (error) {
            console.error("Testimonios: no se pudieron cargar.", error);
            estado.textContent = "No pudimos cargar los testimonios en este momento. Intenta de nuevo más tarde.";
        }
    }

    function mostrarMensaje(contenedor, texto) {
        contenedor.replaceChildren(crear("p", "ep-estado", texto));
    }

    // Testimonio completo: "Testimonio", foto, nombre (título de la página) y rol,
    // y debajo el mensaje con su formato.
    async function cargarTestimonio(contenedor) {
        var id = new URLSearchParams(window.location.search).get("id");
        if (!id || !/^\d+$/.test(id)) {
            mostrarMensaje(contenedor, "No se especificó ningún testimonio.");
            return;
        }

        var testimonio;
        try {
            var cliente = await window.obtenerClienteSupabase();
            var respuesta = await cliente
                .from("testimonios")
                .select("nombre, rol, mensaje, foto_url")
                .eq("id", id)
                .eq("visible", true)
                .maybeSingle();
            if (respuesta.error) throw respuesta.error;
            testimonio = respuesta.data;
        } catch (error) {
            console.error("Testimonios: no se pudo cargar el testimonio.", error);
            mostrarMensaje(contenedor, "No se pudo cargar el testimonio. Intenta de nuevo más tarde.");
            return;
        }
        if (!testimonio) {
            mostrarMensaje(contenedor, "Este testimonio no existe o ya no está disponible.");
            return;
        }

        document.title = "Testimonio de " + testimonio.nombre + " | CCI AL/Colombia";
        var etiqueta = crear("span", "ep-fecha", "Testimonio");

        var cabecera = crear("div", "ep-autor grande tt-cabecera");
        if (testimonio.foto_url) cabecera.appendChild(fotoDe(testimonio, true));
        var datos = crear("div", "ep-autor-datos");
        datos.appendChild(crear("h1", "ep-articulo-titulo tt-nombre", testimonio.nombre));
        if (testimonio.rol) datos.appendChild(crear("span", "ep-autor-rol", testimonio.rol));
        cabecera.appendChild(datos);

        // El mensaje es HTML con formato escrito en el panel (igual que el contenido de un artículo).
        var cuerpo = crear("div", "ep-contenido");
        cuerpo.innerHTML = testimonio.mensaje || "";
        contenedor.replaceChildren(etiqueta, cabecera, cuerpo);
    }

    function iniciar() {
        var lista = document.getElementById("testimonios-grid");
        var estado = document.getElementById("tt-estado");
        if (lista && estado) cargarLista(lista, estado); // si no están, la sección está deshabilitada

        var testimonio = document.getElementById("tt-testimonio");
        if (testimonio) cargarTestimonio(testimonio);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", iniciar);
    } else {
        iniciar();
    }
})();
