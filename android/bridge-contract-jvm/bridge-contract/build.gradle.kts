plugins {
  kotlin("jvm") version "2.0.21"
}

repositories {
  mavenCentral()
}

dependencies {
  implementation(kotlin("stdlib"))
  implementation("org.json:json:20240303")
  testImplementation("junit:junit:4.13.2")
}

kotlin {
  jvmToolchain(17)
}

val moduleRoot = rootProject.projectDir.parentFile!!

val prepareMapperSources by tasks.registering(Sync::class) {
  from(moduleRoot.resolve("src/main/java/expo/modules/applemusic/AppleMusicJsonMapper.kt"))
  into(layout.buildDirectory.dir("mapper-src/expo/modules/applemusic"))
}

sourceSets {
  main {
    kotlin.setSrcDirs(listOf(layout.buildDirectory.dir("mapper-src")))
  }
  test {
    kotlin.srcDir(moduleRoot.resolve("src/test/java"))
    resources.srcDir(moduleRoot.resolve("src/test/resources"))
  }
}

tasks.named("compileKotlin") {
  dependsOn(prepareMapperSources)
}

tasks.test {
  useJUnit()
}
