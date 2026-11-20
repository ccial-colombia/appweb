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

    // Título opcional del testimonio (columna "titulo", ver supabase/testimonios_titulo.sql).
    function tituloDe(testimonio) {
        return String(testimonio.titulo || "").trim();
    }

    // Tarjeta: comillas, título (si tiene), resumen del testimonio, enlace para leerlo
    // completo y, al pie, quién lo da (foto, nombre y rol), como el autor de un artículo.
    // El encabezado de la tarjeta (h3) es el título o, si no hay, el nombre.
    function tarjeta(testimonio) {
        var columna = crear("div", "col-12 col-md-6 col-lg-4");
        var caja = crear("article", "ep-tarjeta tt-tarjeta");
        caja.appendChild(crear("span", "tt-comillas", "“")).setAttribute("aria-hidden", "true");

        var titulo = tituloDe(testimonio);
        if (titulo) {
            var encabezado = crear("h3", "ep-tarjeta-titulo");
            var enlaceTitulo = crear("a", null, titulo);
            enlaceTitulo.href = enlaceTestimonio(testimonio.id);
            encabezado.appendChild(enlaceTitulo);
            caja.appendChild(encabezado);
        }

        var texto = resumen(testimonio.mensaje);
        if (texto) caja.appendChild(crear("p", "ep-resumen tt-resumen", texto));

        var leer = crear("a", "ep-leer", "Leer testimonio");
        leer.href = enlaceTestimonio(testimonio.id);
        leer.setAttribute("aria-label", "Leer el testimonio de " + testimonio.nombre);
        caja.appendChild(leer);

        var autor = crear("div", "ep-autor");
        if (testimonio.foto_url) autor.appendChild(fotoDe(testimonio, false));
        var datos = crear("div", "ep-autor-datos");
        datos.appendChild(crear(titulo ? "span" : "h3", "ep-autor-nombre tt-nombre-tarjeta", testimonio.nombre));
        if (testimonio.rol) datos.appendChild(crear("span", "ep-autor-rol", testimonio.rol));
        autor.appendChild(datos);
        caja.appendChild(autor);

        columna.appendChild(caja);
        return columna;
    }

    async function cargarLista(lista, estado) {
        try {
            var cliente = await window.obtenerClienteSupabase();
            // "*" y no la lista de columnas: así funciona aunque todavía no exista
            // la columna "titulo" (antes de ejecutar supabase/testimonios_titulo.sql).
            var respuesta = await cliente
                .from("testimonios")
                .select("*")
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

    // Testimonio completo, como un artículo de El Punto:
    //   con título -> "Testimonio", el título y debajo quién lo da (foto, nombre y rol)
    //   sin título -> "Testimonio" y quién lo da, con el nombre como título de la página
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
                .select("*") // ver cargarLista(): funciona con o sin la columna "titulo"
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

        var titulo = tituloDe(testimonio);
        document.title = (titulo ? titulo + " · " : "") + "Testimonio de " + testimonio.nombre + " | CCI AL/Colombia";
        var partes = [crear("span", "ep-fecha", "Testimonio")];
        if (titulo) partes.push(crear("h1", "ep-articulo-titulo", titulo));

        var cabecera = crear("div", "ep-autor grande" + (titulo ? "" : " tt-cabecera"));
        if (testimonio.foto_url) cabecera.appendChild(fotoDe(testimonio, true));
        var datos = crear("div", "ep-autor-datos");
        datos.appendChild(titulo
            ? crear("span", "ep-autor-nombre", testimonio.nombre)
            : crear("h1", "ep-articulo-titulo tt-nombre", testimonio.nombre));
        if (testimonio.rol) datos.appendChild(crear("span", "ep-autor-rol", testimonio.rol));
        cabecera.appendChild(datos);
        partes.push(cabecera);

        // El mensaje es HTML con formato escrito en el panel (igual que el contenido de un artículo).
        var cuerpo = crear("div", "ep-contenido");
        cuerpo.innerHTML = testimonio.mensaje || "";
        partes.push(cuerpo);
        contenedor.replaceChildren.apply(contenedor, partes);
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
