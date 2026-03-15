allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val project = this
    fun configure() {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                val namespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                val currentNamespace = android.javaClass.getMethod("getNamespace").invoke(android)
                if (currentNamespace == null) {
                    val newNamespace = "com.medtrackai.${project.name.replace("-", "_").replace(".", "_")}"
                    namespaceMethod.invoke(android, newNamespace)
                    println("Injected namespace $newNamespace into ${project.name}")
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    if (project.state.executed) {
        configure()
    } else {
        project.afterEvaluate { configure() }
    }

    // Surgical fix for problematic plugins with 'package' in AndroidManifest.xml
    project.tasks.configureEach {
        if (name.contains("Manifest") && name.contains("process", ignoreCase = true)) {
            doFirst {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    var content = manifestFile.readText()
                    if (content.contains("package=")) {
                        content = content.replace(Regex("package=\"[^\"]*\""), "")
                        manifestFile.writeText(content)
                        println("Surgically removed package attribute from ${project.name} manifest")
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
