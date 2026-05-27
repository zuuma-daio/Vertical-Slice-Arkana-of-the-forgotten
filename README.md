Proyecto de Videojuego Roguelike Deckbuilder
Descripción
Este proyecto es un videojuego roguelike deckbuilder desarrollado en Godot Engine 4.3, que combina mecánicas estratégicas de construcción de mazos con elementos narrativos impulsados por inteligencia artificial.
El juego presenta una temática cultural única, incorporando facciones inspiradas en civilizaciones históricas y mitológicas como Mapuche, Jomon, Nok y Sumeria.
El sistema de combate se basa en turnos donde el jugador utiliza cartas con efectos variados para atacar, defenderse y aplicar estados al enemigo. 
Cada partida ofrece una experiencia única gracias a la generación procedural de mazos, la personalización de cartas con variantes de mejora, y la progresión a través de múltiples pisos de dificultad.
La arquitectura del proyecto está diseñada para ser modular y escalable, separando claramente la lógica de juego, la gestión de efectos, la interfaz de usuario y los recursos visuales.


Tecnologías usadas
Godot Engine 4.3 (versión estable oficial)
GDScript como lenguaje principal de programación
OpenGL API 3.3 para renderizado
Sistema de recursos (.tres) para definiciones de cartas
Autoloads para gestión de estado global (RunManager, EffectResolver, CardDatabase)
Señales y conexiones para comunicación entre nodos
Sistema de animaciones con Tween para transiciones visuales
Control nodes para interfaz de usuario y Node2D para elementos de gameplay


Funcionalidades
Sistema de Cartas
Cuatro facciones únicas con mecánicas diferenciadas: Mapuche, Jomon, Nok y Sumeria
Efectos de carta modulares: robo, protección, quemadura, reducción de daño, multiplicadores, auras y condicionales
Sistema de mejoras de cartas con variantes "calma" y "agresiva" que modifican estadísticas y efectos
Recuperación de cartas desde el descarte hacia la mano o el mazo
Efectos condicionales que se activan según el estado del combate (turno de defensa, enemigo quemado, etc.)

Sistema de Combate
Combate por turnos con fases de ataque y defensa claramente diferenciadas
Cálculo de daño con soporte para bonificaciones, multiplicadores y reducciones
Sistema de protección que absorbe daño durante la fase defensiva
Estado de quemadura acumulable que inflige daño al enemigo al inicio de su turno
Buffs y debuffs con duración configurable (este turno, N turnos, permanente)

Gestión de Mazo y Mano
Límite de mano configurable mediante reliquias (base: 7 cartas, con reliquia: 8 cartas)
Sistema de descarte visual con selección interactiva de cartas
Sincronización entre estado lógico (RunManager) y representación visual (Deck/Mano)
Animaciones de robo, descarte y recuperación de cartas
Reposicionamiento dinámico de cartas en mano con disposición en arco circular

Progresión y Personalización
Sistema de reliquias que otorgan beneficios persistentes durante la partida
Pantalla de recompensas al finalizar cada combate con opciones de cartas, reliquias o curación
Generación procedural de mazos iniciales basada en facciones seleccionadas
Múltiples pisos de dificultad con enemigos progresivamente más desafiantes

Arquitectura Técnica
Sistema de efectos basado en componentes (EffectComponent) con factory pattern
Contexto de combate (CombatContext) que centraliza el estado temporal de la batalla
Resolución de efectos por fases (PRE-descarte y POST-descarte) para manejo correcto de dependencias
Base de datos de cartas (CardDatabase) con carga dinámica desde recursos .tres
Separación clara entre lógica de juego, gestión de estado y presentación visual


Estado actual

Funcionalidades Implementadas
Sistema base de combate por turnos con fases de ataque y defensa
Cuatro facciones de cartas con efectos únicos y funcionales
Sistema de efectos modular con soporte para condicionales, auras y multiplicadores
Gestión de mazo con robo, descarte y recuperación visual y lógica
Sincronización entre estado lógico (RunManager) y representación visual
Sistema de reliquias con efectos persistentes
Progresión por pisos con pantalla de recompensas
Interfaz de usuario con indicadores de protección, quemadura y daño enemigo

Mejoras Recientes
Corrección del timing de efectos de robo para ejecutarse después del descarte lógico
Implementación de sistema de fases PRE/POST-descarte para efectos dependientes del estado de mano
Solución de conflictos de tipado en Godot 4.3 para compatibilidad con Node2D y Control
Optimización del reposicionamiento de cartas en mano y zona de descarte
Mejora en la gestión de buffs pendientes con marcado de origen para aplicación en turno correcto

Pendientes y Próximos Pasos
Implementación completa del sistema de selección visual para descarte con confirmación
Expansión del sistema narrativo con integración de IA para generación de texto contextual
Balanceo de cartas y efectos basado en testing de partidas completas
Añadir más enemigos y configuraciones de piso para mayor variedad
Implementar sistema de guardado de progreso entre sesiones
Optimización de rendimiento para partidas de larga duración
Documentación técnica adicional para nuevos contribuyentes


Notas Técnicas
El proyecto requiere Godot Engine 4.3 stable para compilación y ejecución
Compatible con plataformas de escritorio (Windows, Linux, macOS) mediante exportación estándar
El sistema de efectos está diseñado para ser extensible mediante la adición de nuevos EffectComponent
La arquitectura permite la incorporación de nuevas facciones sin modificar el núcleo del sistema de combate
