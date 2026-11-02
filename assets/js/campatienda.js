// CampaTienda: muestra los productos de la tabla "productos" de Supabase.
// Se administran desde admin.html, en la pestaña "CampaTienda".
// Requiere assets/js/secciones.js (obtenerClienteSupabase) y Bootstrap (modal de la foto).
(function () {
    "use strict";

    var CORREO_PEDIDOS = "comunicacionesccialcol@gmail.com";
    var formatoPrecio = new Intl.NumberFormat("es-CO", {
        style: "currency",
        currency: "COP",
        maximumFractionDigits: 0
    });

    function crear(etiqueta, clase, texto) {
        var el = document.createElement(etiqueta);
        if (clase) el.className = clase;
        if (texto != null) el.textContent = texto;
        return el;
    }

    function listaOpciones(texto) {
        return (texto || "").split(",")
            .map(function (o) { return o.trim(); })
            .filter(Boolean);
    }

    // Correo con el pedido ya escrito; el miembro solo completa sus datos.
    function enlacePedido(producto, opciones) {
        var lineas = [
            "Hola, quiero pedir este producto de CampaTienda:",
            "",
            "Producto: " + producto.nombre
        ];
        if (opciones.length) lineas.push("Talla u opción (" + opciones.join(", ") + "): ");
        lineas.push("Cantidad: 1", "", "Mi nombre: ", "Ciudad: ", "Teléfono: ");
        return "mailto:" + CORREO_PEDIDOS +
            "?subject=" + encodeURIComponent("CampaTienda - " + producto.nombre) +
            "&body=" + encodeURIComponent(lineas.join("\r\n"));
    }

    function ampliarFoto(producto) {
        var modal = document.getElementById("ct-modal-foto");
        if (!modal || !window.bootstrap) {
            window.open(producto.imagen_url, "_blank", "noopener");
            return;
        }
        modal.querySelector(".modal-title").textContent = producto.nombre;
        var img = modal.querySelector("img");
        img.src = producto.imagen_url;
        img.alt = producto.nombre;
        // El sitio usa Bootstrap 5.0.1, que no tiene getOrCreateInstance.
        (bootstrap.Modal.getInstance(modal) || new bootstrap.Modal(modal)).show();
    }

    function tarjeta(producto) {
        var agotado = producto.disponible === false;
        var opciones = listaOpciones(producto.opciones);

        var columna = crear("div", "col-12 col-sm-6 col-lg-4 col-xl-3");
        var articulo = crear("article", "ct-producto" + (agotado ? " agotado" : ""));

        // Foto (clic para ampliar)
        var foto;
        if (producto.imagen_url) {
            foto = crear("button", "ct-producto-foto");
            foto.type = "button";
            foto.setAttribute("aria-label", "Ampliar foto: " + producto.nombre);
            var img = crear("img");
            img.src = producto.imagen_url;
            img.alt = producto.nombre;
            img.loading = "lazy";
            img.decoding = "async";
            foto.appendChild(img);
            foto.addEventListener("click", function () { ampliarFoto(producto); });
        } else {
            foto = crear("div", "ct-producto-foto sin-foto", "Foto próximamente");
        }
        if (agotado) foto.appendChild(crear("span", "ct-agotado-etiqueta", "Agotado"));
        articulo.appendChild(foto);

        // Datos
        var cuerpo = crear("div", "ct-producto-cuerpo");
        cuerpo.appendChild(crear("h3", "ct-producto-nombre", producto.nombre));
        if (producto.descripcion) {
            cuerpo.appendChild(crear("p", "ct-producto-desc", producto.descripcion));
        }
        if (opciones.length) {
            var ul = crear("ul", "ct-producto-opciones");
            ul.setAttribute("aria-label", "Tallas u opciones");
            opciones.forEach(function (o) { ul.appendChild(crear("li", null, o)); });
            cuerpo.appendChild(ul);
        }

        // Precio y botón de pedido
        var pie = crear("div", "ct-producto-pie");
        var tienePrecio = producto.precio != null;
        pie.appendChild(crear("span", "ct-producto-precio" + (tienePrecio ? "" : " consultar"),
            tienePrecio ? formatoPrecio.format(producto.precio) : "Precio a consultar"));
        if (agotado) {
            var sinStock = crear("span", "btn btn-secondary ct-btn-pedir disabled", "Agotado");
            sinStock.setAttribute("aria-disabled", "true");
            pie.appendChild(sinStock);
        } else {
            var pedir = crear("a", "btn btn-primary ct-btn-pedir", "Pedir");
            pedir.href = enlacePedido(producto, opciones);
            pedir.setAttribute("aria-label", "Pedir " + producto.nombre + " por correo");
            pie.appendChild(pedir);
        }
        cuerpo.appendChild(pie);

        articulo.appendChild(cuerpo);
        columna.appendChild(articulo);
        return columna;
    }

    function mostrarError(estado) {
        var enlace = crear("a", "text-primary", CORREO_PEDIDOS);
        enlace.href = "mailto:" + CORREO_PEDIDOS + "?subject=CampaTienda";
        estado.textContent = "No pudimos cargar los productos en este momento. Escríbenos a ";
        estado.appendChild(enlace);
        estado.appendChild(document.createTextNode("."));
        estado.hidden = false;
    }

    async function cargarProductos() {
        var lista = document.getElementById("ct-lista");
        var estado = document.getElementById("ct-estado");
        if (!lista || !estado) return; // sección deshabilitada desde el panel

        try {
            var cliente = await window.obtenerClienteSupabase();
            var respuesta = await cliente
                .from("productos")
                .select("id, imagen_url, nombre, descripcion, precio, opciones, disponible")
                .eq("visible", true)
                .order("orden", { ascending: true })
                .order("id", { ascending: true });
            if (respuesta.error) throw respuesta.error;

            if (!respuesta.data || respuesta.data.length === 0) {
                estado.textContent = "Pronto tendremos productos disponibles.";
                return;
            }
            lista.replaceChildren.apply(lista, respuesta.data.map(tarjeta));
            estado.hidden = true;
        } catch (error) {
            console.error("CampaTienda: no se pudieron cargar los productos.", error);
            mostrarError(estado);
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", cargarProductos);
    } else {
        cargarProductos();
    }
})();
