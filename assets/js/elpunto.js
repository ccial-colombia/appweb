// El Punto: revista virtual con los artículos de la tabla "articulos" de Supabase.
// Se administran desde admin.html, en la pestaña "El Punto".
//   elpunto.html  -> tarjetas de los artículos, del más nuevo al más viejo (fecha de ingreso)
//   articulo.html -> un artículo completo (articulo.html?id=...)
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

    // "2026-11-16" -> "16 de noviembre de 2026". Se arma con la fecha local
    // para que la zona horaria del visitante no la corra un día.
    function formatoFecha(valor) {
        var partes = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(valor || ""));
        if (!partes) return "";
        return new Date(Number(partes[1]), Number(partes[2]) - 1, Number(partes[3]))
            .toLocaleDateString("es-CO", { day: "numeric", month: "long", year: "numeric" });
    }

    function elementoFecha(valor) {
        var texto = formatoFecha(valor);
        if (!texto) return null;
        var fecha = crear("time", "ep-fecha", texto);
        fecha.dateTime = String(valor).slice(0, 10);
        return fecha;
    }

    // Texto sin formato del artículo, para el resumen de la tarjeta. Se lee en un
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

    function enlaceArticulo(id) {
        return "articulo.html?id=" + encodeURIComponent(id);
    }

    // Foto, nombre y rol del autor (igual que en los testimonios). Sin autor no se muestra.
    function bloqueAutor(articulo, grande) {
        if (!articulo.autor) return null;
        var autor = crear("div", "ep-autor" + (grande ? " grande" : ""));
        if (articulo.foto_url) {
            var foto = crear("img", "ep-autor-foto");
            foto.src = articulo.foto_url;
            foto.alt = "Foto de " + articulo.autor;
            foto.decoding = "async";
            if (!grande) foto.loading = "lazy";
            autor.appendChild(foto);
        }
        var datos = crear("div", "ep-autor-datos");
        datos.appendChild(crear("span", "ep-autor-nombre", articulo.autor));
        if (articulo.rol) datos.appendChild(crear("span", "ep-autor-rol", articulo.rol));
        autor.appendChild(datos);
        return autor;
    }

    function tarjeta(articulo) {
        var columna = crear("div", "col-12 col-md-6 col-lg-4");
        var caja = crear("article", "ep-tarjeta");

        var fecha = elementoFecha(articulo.fecha_ingreso);
        if (fecha) caja.appendChild(fecha);

        var titulo = crear("h3", "ep-tarjeta-titulo");
        var enlaceTitulo = crear("a", null, articulo.titulo);
        enlaceTitulo.href = enlaceArticulo(articulo.id);
        titulo.appendChild(enlaceTitulo);
        caja.appendChild(titulo);

        var texto = resumen(articulo.contenido);
        if (texto) caja.appendChild(crear("p", "ep-resumen", texto));

        var leer = crear("a", "ep-leer", "Leer artículo");
        leer.href = enlaceArticulo(articulo.id);
        leer.setAttribute("aria-label", "Leer artículo: " + articulo.titulo);
        caja.appendChild(leer);

        var autor = bloqueAutor(articulo, false);
        if (autor) caja.appendChild(autor);

        columna.appendChild(caja);
        return columna;
    }

    async function cargarLista(lista, estado) {
        try {
            var cliente = await window.obtenerClienteSupabase();
            var respuesta = await cliente
                .from("articulos")
                .select("id, titulo, autor, rol, foto_url, contenido, fecha_ingreso")
                .eq("visible", true)
                .order("fecha_ingreso", { ascending: false })
                .order("id", { ascending: false });
            if (respuesta.error) throw respuesta.error;

            if (!respuesta.data || respuesta.data.length === 0) {
                estado.textContent = "Pronto publicaremos nuestros primeros artículos.";
                return;
            }
            lista.replaceChildren.apply(lista, respuesta.data.map(tarjeta));
            estado.hidden = true;
        } catch (error) {
            console.error("El Punto: no se pudieron cargar los artículos.", error);
            estado.textContent = "No pudimos cargar los artículos en este momento. Intenta de nuevo más tarde.";
        }
    }

    function mostrarMensaje(contenedor, texto) {
        contenedor.replaceChildren(crear("p", "ep-estado", texto));
    }

    async function cargarArticulo(contenedor) {
        var id = new URLSearchParams(window.location.search).get("id");
        if (!id || !/^\d+$/.test(id)) {
            mostrarMensaje(contenedor, "No se especificó ningún artículo.");
            return;
        }

        var articulo;
        try {
            var cliente = await window.obtenerClienteSupabase();
            var respuesta = await cliente
                .from("articulos")
                .select("titulo, autor, rol, foto_url, contenido, fecha_ingreso")
                .eq("id", id)
                .eq("visible", true)
                .maybeSingle();
            if (respuesta.error) throw respuesta.error;
            articulo = respuesta.data;
        } catch (error) {
            console.error("El Punto: no se pudo cargar el artículo.", error);
            mostrarMensaje(contenedor, "No se pudo cargar el artículo. Intenta de nuevo más tarde.");
            return;
        }
        if (!articulo) {
            mostrarMensaje(contenedor, "Este artículo no existe o ya no está disponible.");
            return;
        }

        document.title = articulo.titulo + " | El Punto · CCI AL/Colombia";
        var partes = [];
        var fecha = elementoFecha(articulo.fecha_ingreso);
        if (fecha) partes.push(fecha);
        partes.push(crear("h1", "ep-articulo-titulo", articulo.titulo));
        var autor = bloqueAutor(articulo, true);
        if (autor) partes.push(autor);
        // El contenido es HTML con formato escrito en el panel (igual que en testimonio.html).
        var cuerpo = crear("div", "ep-contenido");
        cuerpo.innerHTML = articulo.contenido || "";
        partes.push(cuerpo);
        contenedor.replaceChildren.apply(contenedor, partes);
    }

    function iniciar() {
        var lista = document.getElementById("ep-lista");
        var estado = document.getElementById("ep-estado");
        if (lista && estado) cargarLista(lista, estado); // si no están, la sección está deshabilitada

        var articulo = document.getElementById("ep-articulo");
        if (articulo) cargarArticulo(articulo);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", iniciar);
    } else {
        iniciar();
    }
})();
