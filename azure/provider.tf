provider "azure" {
    settings_file="${file(${var.azure_credentials_file})}"
}
