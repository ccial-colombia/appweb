-- ============================================================
-- Datos actuales de Cursos y Talleres
-- Ejecutar DESPUÉS de cursos_talleres.sql
-- Supabase Dashboard > SQL Editor > New query
--
-- Carga los cursos y talleres que hoy están escritos a mano en
-- exclusivo.html. Las imágenes apuntan a los archivos locales de
-- assets/images/; al reemplazarlas desde el panel se guardará la
-- URL del bucket "contenido".
--
-- Vacía las tablas antes de insertar para no duplicar si se corre
-- más de una vez. Si ya cargaste datos propios, quita los TRUNCATE.
-- ============================================================

truncate table public.cursos restart identity;

insert into public.cursos (imagen_url, nombre, descripcion_corta, descripcion, orden, visible) values
  ('assets/images/construyendo20relaciones-695x899.png',
   'Construyendo Relaciones',
   'Curso base y puerta de entrada al proceso formativo de CCI AL.',
   'Este curso prepara a los participantes para servir como confidentes, entendiendo que nadie puede dar a otros lo que no ha trabajado primero en su propia vida.<br><br>Profundiza en la relación con Dios, consigo mismo, con el prójimo y con la creación de Dios; a la luz de principios bíblicos.',
   1, true),

  ('assets/images/facilitando20acertijos-695x899.png',
   'Facilitando Acertijos - Básico',
   'Este curso equipa a líderes para facilitar el aprendizaje a través de la experiencia y la reflexión guiada.',
   'Usa el Ciclo de Kolb de aprendizaje experiencial. Enseña el proceso paso a paso para elegir actividades que fortalecen el trabajo en equipo; cuidando de la seguridad y guiando al grupo a reflexionar y aprender de sus experiencias para incorporar el aprendizaje a sus vidas.',
   2, true),

  ('assets/images/facilitando20crecimiento-695x899.png',
   'Facilitando Crecimiento',
   'Este curso forma líderes que acompañan procesos de crecimiento espiritual de manera intencional.',
   'Aprendemos a facilitar el crecimiento a través de la consejería bíblica, la disciplina inductiva y el aprendizaje experiencial; comprendiendo los estilos de aprendizaje y las características de las edades.',
   3, true),

  ('assets/images/programando20campamentos-695x899.png',
   'Programando Campamentos',
   'Este curso equipa líderes para diseñar experiencias de campamento que conectan recreación, comunidad y el mensaje de Cristo.',
   'A través de un proceso de 12 pasos, aprendemos a crear programas intencionales y contextualizados.',
   4, true),

  ('assets/images/creando20encuentros20biblicos20en20comunidad-695x899.png',
   'Creando Encuentros Bíblicos en Comunidad',
   'Este curso forma líderes con pensamiento bíblico, capaces de crear Encuentros Bíblicos en comunidad (EBC) que guían a otros a observar, interpretar y aplicar la Palabra de Dios.',
   'Los EBC crean espacios donde la Biblia se vive en comunidad.',
   5, true);

truncate table public.talleres restart identity;

insert into public.talleres (imagen_url, nombre, descripcion_corta, descripcion, orden, visible) values
  ('assets/images/portada-dpc-297x385.jpg',
   'Taller Reglas del Cerebro',
   null,
   'Aprendemos cómo funciona el cerebro para enseñar y aprender de manera más efectiva.',
   1, true),

  ('assets/images/portada-dpc-297x385.jpg',
   'Taller El Gozo de Trabajo en Equipo',
   null,
   'Descubrimos cómo nuestras diferencias fortalecen el trabajo en equipo cuando hay unidad.',
   2, true),

  ('assets/images/portada-dpc-297x385.jpg',
   'Taller ExpoJuegos',
   null,
   'La recreación con propósito enseña valores y crea ambientes de aprendizaje y comunidad.',
   3, true),

  ('assets/images/portada-dpc-297x385.jpg',
   'Taller El buen Sembrador: La Flor y La Abeja',
   null,
   'Una forma creativa y profunda de enseñar la Palabra de Dios conectando mente, corazón y acción.',
   4, true);
