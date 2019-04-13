package com.example.demo

import com.amazonaws.auth.EnvironmentVariableCredentialsProvider
import com.amazonaws.services.s3.AmazonS3ClientBuilder
import org.springframework.beans.factory.annotation.Value
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController

@RestController
class S3Controller(
        @Value("\${amazonProperties.bucketName}") val bucketName: String
) {
    private val s3client = AmazonS3ClientBuilder.standard()
            .withCredentials(EnvironmentVariableCredentialsProvider())
            .build()

    @PostMapping("/s3/files/{id}")
    fun addFile(@PathVariable id: String,
                @RequestBody content: String) {
        s3client.putObject(bucketName, id, content)
    }

    @GetMapping("/s3/files/{id}")
    fun getFile(@PathVariable id: String): String {
        return s3client.getObject(bucketName, id).objectContent.bufferedReader().use { it.readText() }
    }

}
