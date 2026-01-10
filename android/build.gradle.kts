allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}


subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    // Force compileSdk to 36
                    try {
                        val setCompileSdk = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                        setCompileSdk.invoke(android, 36)
                    } catch (e: Exception) {
                        try {
                            val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                            setCompileSdkVersion.invoke(android, 36)
                        } catch (e2: Exception) {}
                    }

                    // Force JVM Target 17 for compileOptions (Java)
                    val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                    val setSourceCompatibility = compileOptions.javaClass.getMethod("setSourceCompatibility", org.gradle.api.JavaVersion::class.java)
                    val setTargetCompatibility = compileOptions.javaClass.getMethod("setTargetCompatibility", org.gradle.api.JavaVersion::class.java)
                    setSourceCompatibility.invoke(compileOptions, org.gradle.api.JavaVersion.VERSION_17)
                    setTargetCompatibility.invoke(compileOptions, org.gradle.api.JavaVersion.VERSION_17)
                } catch (e: Exception) {}
            }
        }

        // Force JVM Target 17 for KotlinCompile tasks
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
                freeCompilerArgs = freeCompilerArgs + "-Xno-incremental-compilation"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
