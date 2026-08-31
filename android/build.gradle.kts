allprojects {
    repositories {
        maven("https://maven.aliyun.com/repository/public")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
        maven("https://maven.aliyun.com/repository/gradle-plugin")
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
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

// 统一 Kotlin JVM target 与各模块 Java 编译目标一致，
// 修复 flutter_js 插件 Kotlin(1.8) vs Java(11) 不一致导致的构建失败
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val ext = project.extensions.findByName("android")
        if (ext != null) {
            val javaTarget = try {
                val opts = ext.javaClass.getMethod("getCompileOptions").invoke(ext)
                val src = opts.javaClass.getMethod("getSourceCompatibility").invoke(opts)
                src.toString()
            } catch (_: Exception) {
                null
            }
            if (javaTarget != null && javaTarget.isNotEmpty()) {
                compilerOptions.jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget)
                )
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
