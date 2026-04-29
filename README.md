# 🥖 App de Inventario - Panadería

¡Bienvenidos al repositorio oficial del proyecto! Esta aplicación está diseñada para ayudar a los panaderos a gestionar su producción diaria, controlar el stock de productos (cachitos, pan de bono, etc.) y visualizar precios en tiempo real.

---

## 👥 Equipo y Roles
* **José (Arquitecto / Líder Técnico):** Estructura del proyecto, base de datos y despliegue.
* **Xavier (UI / Frontend):** Diseño en Figma y creación de widgets en Flutter.
* **Valeria (Analista / QA):** Backlog de usuario, definición de datos y pruebas.

---

## 🏗️ Estructura del Proyecto

Para mantener el código limpio, utilizaremos la siguiente jerarquía de carpetas:

* `lib/models/`: Definición de las clases de datos (ej: `pan_model.dart`).
* `lib/screens/`: Pantallas principales (Inventario, Registro, Detalles).
* `lib/widgets/`: Componentes reutilizables (Botones, Cards de producto).
* `lib/services/`: Lógica de la base de datos y almacenamiento.
* `lib/theme/`: Configuración de colores y tipografía (Google Fonts).

---

## 🛠️ Tecnologías Utilizadas
* **Framework:** [Flutter](https://flutter.dev)
* **Lenguaje:** Dart
* **Estado:** Provider
* **Base de Datos:** SQLite (`sqflite`)
* **Diseño:** Material 3 + Google Fonts (Poppins)

---

## 🚀 Guía de Inicio para el Equipo

Si acabas de clonar este repositorio, sigue estos pasos:

1.  **Obtener dependencias:**
    Ejecuta en la terminal:
    ```bash
    flutter pub get
    ```

2.  **Configurar el SDK:**
    Asegúrate de tener instalada la versión de Flutter `3.2.0` o superior.

3.  **Ejecutar la App:**
    Selecciona tu dispositivo (celular o emulador) y presiona `F5` en VS Code.

---

## 📅 Planificación Semana 1
- [x] Inicialización del repositorio (José).
- [ ] Diseño de las 3 pantallas principales (Xavier).
- [ ] Definición del Diccionario de Datos (Valeria).
- [ ] Configuración del esqueleto de carpetas y dependencias (José).

---
*Nota: Este proyecto es de uso académico y está en fase de desarrollo activo.*