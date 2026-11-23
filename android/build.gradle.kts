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
// The onnxruntime plugin is built against Android 33, but its AndroidX
// dependencies need 34 or newer. Raise the compile version for that plugin only.
subprojects {
    if (project.name == "onnxruntime") {
        afterEvaluate {
            extensions.findByName("android")?.let { ext ->
                try {
                    ext.withGroovyBuilder { "compileSdkVersion"(36) }
                } catch (e: Exception) {
                    ext.withGroovyBuilder { "setCompileSdk"(36) }
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
