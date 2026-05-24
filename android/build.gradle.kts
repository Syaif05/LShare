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

gradle.projectsEvaluated {
    subprojects {
        val javaCompileTasks = tasks.withType<JavaCompile>()
        val kotlinCompileTasks = tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
        
        var javaTarget: String? = null
        javaCompileTasks.forEach { task ->
            javaTarget = task.targetCompatibility
        }
        
        if (javaTarget != null) {
            val targetString = javaTarget!!
            kotlinCompileTasks.forEach { task ->
                task.kotlinOptions.jvmTarget = targetString
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
