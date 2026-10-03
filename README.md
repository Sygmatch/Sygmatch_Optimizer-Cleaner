# Sygmatch Optimizer Pro

Herramienta para Windows 10 y 11 que te ayuda a mejorar la privacidad, el rendimiento y el mantenimiento de tu equipo, con una consola que muestra en todo momento qué se está haciendo.

## Requisitos

- Windows 10 o Windows 11
- Permisos de administrador (el programa los pide automáticamente al abrirse)

## Antes de aplicar cualquier cambio

Al abrir el programa, se crea automáticamente un **punto de restauración** de Windows (si no hay uno reciente), para que puedas volver atrás desde "Restaurar sistema" si algo no te convence.

Junto a cada opción hay un icono **"?"**: al pasar el puntero o hacer clic sobre él, se explica qué hace esa opción.

## Leyenda (junto a cada opción)

| Etiqueta | Significado |
|---|---|
| 🟢 **Reversible** | Puedes desmarcar la casilla en cualquier momento y el cambio se deshace. |
| 🟡 **Parcial** | El ajuste se puede deshacer, pero alguna parte (como una app eliminada) no se puede restaurar desde el programa. |
| 🔴 **No reversible** | La acción no se puede deshacer (por ejemplo, borrar archivos). |
| 🔵 **Seguro / Solo informa** | No representa ningún riesgo; algunas opciones solo muestran información sin cambiar nada. |
| ⚠️ **Alto riesgo** | Reduce la seguridad de tu equipo. Pide una confirmación adicional antes de aplicarse. |

---

## 🔒 Privacidad, Bloatware e IA

| Opción | Qué hace | Tipo |
|---|---|---|
| **Quitar apps innecesarias (bloatware)** | Desinstala apps preinstaladas que casi nadie usa (Candy Crush, Spotify, Clima, Noticias, Mapas, Skype, Solitario, etc.) y evita que Windows instale más por su cuenta. | 🔴 No reversible* |
| **Privacidad y telemetría al mínimo** | Reduce al mínimo posible los datos de uso que Windows envía a Microsoft y desactiva la publicidad personalizada. | 🟢 Reversible |
| **Desactivar historial de actividad** | Evita que Windows guarde un registro de las apps, documentos y páginas que usaste (Línea de tiempo). | 🟢 Reversible |
| **Desactivar experiencias personalizadas** | Evita que Microsoft use tus datos de diagnóstico para mostrarte sugerencias y consejos personalizados. | 🟢 Reversible |
| **Quitar sugerencias y anuncios de Inicio** | Elimina los anuncios y apps recomendadas que a veces aparecen en el menú Inicio y la pantalla de bloqueo. | 🟢 Reversible |
| **Desactivar telemetría de Office** | Impide que Word, Excel y el resto de Office envíen datos de uso a Microsoft. | 🟢 Reversible |
| **Desactivar asistentes (Cortana / Copilot)** | Apaga el asistente de voz o de IA de Windows: Cortana en Windows 10, Copilot (y Recall) en Windows 11. | 🟡 Parcial* |
| **Desactivar Autoplay y Autorun** | Evita que una memoria USB ejecute programas automáticamente al conectarla, protegiéndote de virus. | 🟢 Reversible |
| **Mostrar extensiones de archivo** | Muestra el tipo real de cada archivo (.exe, .pdf, .docx) para detectar archivos peligrosos disfrazados, como "factura.pdf.exe". | 🟢 Reversible |

\* La app que se elimina no se puede reinstalar desde el programa; habría que reinstalarla desde Microsoft Store.

## 🎮 Rendimiento y Juegos

| Opción | Qué hace | Tipo |
|---|---|---|
| **Efectos visuales balanceados** | Quita animaciones y transparencias para que Windows se sienta más ágil, conservando una apariencia cuidada (fuentes suaves, ventanas con contenido al moverlas). | 🟢 Reversible |
| **Reducir retrasos de interfaz** | Hace que los programas de inicio y los menús respondan más rápido, quitando esperas artificiales. | 🟢 Reversible |
| **Activar Modo Juego** | Activa el Modo Juego de Windows, que prioriza los recursos del equipo para el juego que tienes abierto. | 🟢 Reversible |
| **Activar HAGS (GPU por hardware)** | Deja que la tarjeta gráfica administre su propia carga de trabajo en vez de la CPU, lo que puede reducir la latencia en juegos. Solo se activa si tu tarjeta gráfica y su driver lo permiten; si no, no cambia nada. Pide reiniciar. | 🟢 Reversible |
| **Desactivar grabación DVR / Xbox Game Bar** | Apaga la grabación automática en segundo plano de Xbox Game Bar, que puede consumir recursos mientras juegas. | 🟢 Reversible |
| **Cierre rápido de apps + quitar Bing** | Cierra más rápido los programas que no responden al apagar el equipo, y quita los resultados web de Bing de la búsqueda de Windows. | 🟢 Reversible |
| **Desactivar SysMain (solo en SSD)** | Apaga un servicio que precarga programas en la memoria. Solo se desactiva si tu disco es de estado sólido (SSD), porque en un disco duro tradicional (HDD) sí ayuda y no se toca. | 🟢 Reversible |

## 🌐 RED, Energía y Sistema

| Opción | Qué hace | Tipo |
|---|---|---|
| **Desactivar Optimización de Entrega** | Evita que tu PC comparta partes de las actualizaciones de Windows con otros equipos por internet, ahorrando tu ancho de banda de subida. | 🟢 Reversible |
| ** RED: reducir latencia (Nagle/QoS)** | Ajusta la configuración de red para reducir los tiempos de respuesta, útil sobre todo en juegos en línea. Pide reiniciar. | 🟢 Reversible |
| **Plan de energía Alto rendimiento** | Pone el equipo en modo de máximo rendimiento. Solo se aplica en computadoras de escritorio, nunca en laptops, para no gastar la batería. | 🟢 Reversible |
| **Desactivar Hibernación** | Libera varios GB de espacio en disco al apagar la hibernación (y el Inicio rápido). En laptops, el programa te avisa antes, porque la hibernación suele ser la red de seguridad cuando la batería está por agotarse. | 🟢 Reversible |
| **Desactivar tareas de telemetría** | Apaga tareas internas de Windows que recopilan datos de uso del equipo (no afecta a Windows Update). | 🟢 Reversible |
| **Barra de tareas: ocultar Widgets/Chat o Noticias** | Oculta los Widgets y el Chat de la barra de tareas en Windows 11, o las Noticias e intereses en Windows 10. | 🟢 Reversible |

## ⚠️ Riesgo Alto

Estas dos opciones **reducen la seguridad** de tu equipo. El programa muestra una advertencia adicional y pide confirmarla antes de aplicarlas.

| Opción | Qué hace | Tipo |
|---|---|---|
| **Desactivar Microsoft Defender** | Apaga la protección en tiempo real del antivirus de Windows. Mientras esté desactivada, virus y ransomware no serán detectados al ejecutarse. Útil solo si usas otro antivirus. | ⚠️ Alto riesgo (reversible) |
| **Desactivar Windows Update** | Detiene las actualizaciones automáticas de Windows, incluidas las de seguridad. | ⚠️ Alto riesgo (reversible) |

## 🛠️ Mantenimiento Avanzado

Estos botones ejecutan la acción de inmediato (no usan casillas ni el botón "Aplicar Cambios").

| Botón | Qué hace | Tipo |
|---|---|---|
| **Ejecutar DISM Completo** | Revisa y repara la imagen del sistema operativo, descargando de Microsoft los archivos dañados que haga falta reemplazar (necesita internet). Puede tardar varios minutos. | 🔵 Seguro |
| **Ejecutar SFC /scannow** | Revisa todos los archivos importantes de Windows y repara los que estén dañados o modificados. | 🔵 Seguro |
| **Limpieza de temporales y caché** | Abre una ventana donde eliges qué limpiar: archivos temporales, caché de actualizaciones, miniaturas, caché de navegadores (sin tocar contraseñas ni historial), etc. Libera espacio en disco. | 🔴 No reversible |
| **Optimización de WinSxS** | Libera espacio ocupado por versiones antiguas de componentes de Windows. Te pregunta si prefieres una limpieza segura o una más agresiva (que impide desinstalar actualizaciones después). | 🔴 No reversible |
| **Analizar almacén de componentes** | Solo muestra cuánto espacio ocupa ese almacén y si Windows recomienda limpiarlo. No borra nada. | 🔵 Solo informa |
| **Restablecer DNS y Winsock** | Soluciona problemas de conexión a internet reiniciando la configuración de red. Pide reiniciar el equipo. | 🔵 Seguro |
| **Verificar y activar TRIM** | Revisa y, si hace falta, activa una función que mantiene saludable y rápido un disco SSD. | 🔵 Seguro |
| **Optimizar unidades** | Optimiza tus discos según su tipo: a los SSD les manda una señal de mantenimiento (TRIM); a los discos duros tradicionales (HDD) los desfragmenta. | 🔵 Seguro |
| **Informe de salud de discos** | Muestra el estado de tus discos (temperatura, desgaste, horas de uso, espacio libre) sin modificar nada. | 🔵 Solo informa |

---

## Modo oscuro / claro

Arriba a la derecha hay un interruptor para cambiar entre modo oscuro y modo claro, según prefieras.

## Aviso

Cada opción se verifica contra el sistema real después de aplicarse: si algo no se pudo confirmar, el programa lo indica en la consola en vez de asumir que funcionó. Aun así, se recomienda tener a mano el punto de restauración y revisar la descripción de cada opción antes de aplicarla.
