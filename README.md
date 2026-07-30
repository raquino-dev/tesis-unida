# Finanzas Inteligentes

Prototipo Flutter para la gestión de finanzas personales y familiares. Actualmente utiliza repositorios mock en memoria para validar funcionalidades, navegación y experiencia de usuario antes de integrar el backend.

## Identidad Android

- Application ID: `com.tesis.finanzasinteligentes`
- Nombre visible: `Finanzas Inteligentes`
- Versión: `0.1.0+1`

## Verificación local

```bash
flutter analyze
flutter test
flutter build apk --debug
```

La configuración de firma y las instrucciones de distribución se encuentran en [docs/BETA_DISTRIBUTION.md](docs/BETA_DISTRIBUTION.md).

El contrato propuesto para el backend .NET 10 se encuentra en [docs/api/README.md](docs/api/README.md).

La arquitectura, las migraciones PostgreSQL y el desarrollo por etapas se encuentran en [docs/backend/README.md](docs/backend/README.md).

## Configuración segura

El repositorio no debe contener credenciales reales. Para firmar Android, copiá
`android/key.properties.example` como `android/key.properties` y completalo solo
en tu entorno local. Los keystores, archivos `.env`, configuraciones Firebase,
cuentas de servicio y artefactos APK/AAB están excluidos mediante `.gitignore`.

Los códigos OTP y de recuperación incluidos en la aplicación son exclusivamente
datos mock para la prueba piloto. No deben reutilizarse al conectar el backend.
