#!/usr/bin/env bash

set -euo pipefail

readonly keychain_service="com.tesis.finanzasinteligentes.upload-key"
readonly keychain_account="rodrigoaquino.dev@gmail.com"
readonly key_alias="finanzas-inteligentes-upload"
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly project_dir="$(cd "${script_dir}/.." && pwd)"
readonly keystore_path="${project_dir}/android/upload-keystore.jks"
readonly android_studio_java="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

if [[ ! -f "${keystore_path}" ]]; then
  echo "No se encontró la clave de carga: ${keystore_path}" >&2
  exit 1
fi

upload_password="$(security find-generic-password \
  -a "${keychain_account}" \
  -s "${keychain_service}" \
  -w)"

cleanup() {
  unset upload_password
  unset PLAY_UPLOAD_KEY_PASSWORD
  unset PLAY_UPLOAD_STORE_PASSWORD
}
trap cleanup EXIT

export JAVA_HOME="${android_studio_java}"
export PATH="${JAVA_HOME}/bin:${PATH}"
export PLAY_UPLOAD_KEY_ALIAS="${key_alias}"
export PLAY_UPLOAD_KEY_PASSWORD="${upload_password}"
export PLAY_UPLOAD_STORE_FILE="${keystore_path}"
export PLAY_UPLOAD_STORE_PASSWORD="${upload_password}"

cd "${project_dir}"
flutter build appbundle --release "$@"
