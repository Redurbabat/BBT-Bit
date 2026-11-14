pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
        google()
    }
}

dependencyResolutionManagement {
    repositories {
        mavenCentral()
        google()
    }
}

rootProject.name = "redbit-apple"

include(":shared")

include(":innertubex")
project(":innertubex").projectDir = file("vendor/innertubex")
