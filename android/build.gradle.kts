allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
plugins {// ...// Add the dependency for the Google services Gradle plugin



    id("com.google.gms.google-services") version "4.4.0" apply false

}