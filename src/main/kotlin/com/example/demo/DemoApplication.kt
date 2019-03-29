package com.example.demo

import com.amazonaws.auth.AWSCredentials
import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.auth.EnvironmentVariableCredentialsProvider
import com.amazonaws.client.builder.AwsClientBuilder
import com.amazonaws.services.s3.AmazonS3Client
import com.amazonaws.services.s3.AmazonS3ClientBuilder
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.stereotype.Component
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import kotlin.random.Random

@SpringBootApplication
class DemoApplication

fun main(args: Array<String>) {
    runApplication<DemoApplication>(*args)
}

@RestController
class C(
        @Value("\${amazonProperties.bucketName}") val bucketName: String
) {
    private val rand = Random.nextInt()
    private val client = AmazonS3ClientBuilder.standard()
            .withCredentials(EnvironmentVariableCredentialsProvider())
            .build()

    @GetMapping("/hello")
    fun hello(@RequestParam name: String?) = "${rand}: Hello ${name ?: "vasya"}!"

    @PostMapping("/file/{id}")
    fun addFile(@PathVariable id: String,
                @RequestBody content: String) {
        client.putObject(bucketName, id, content)
    }

    @GetMapping("/file/{id}")
    fun getFile(@PathVariable id: String): String {
        return client.getObject(bucketName, id).objectContent.bufferedReader().use { it.readText() }
    }

}