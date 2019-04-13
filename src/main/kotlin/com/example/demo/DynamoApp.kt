package com.example.demo

import com.amazonaws.auth.AWSStaticCredentialsProvider
import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.regions.Regions
import com.amazonaws.services.dynamodbv2.AmazonDynamoDB
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBAttribute
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBHashKey
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapper
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapperConfig
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBTable
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController
import kotlin.random.Random

@RestController
class DynamoController(
        val dynamoDBMapper: DynamoDBMapper
) {

    @PostMapping("/dynamo/files")
    fun addDynamoFile(@RequestBody content: String) =
            DynamoEntity(id = Random.nextInt(), value = content)
                    .also { dynamoDBMapper.save(it) }

    @GetMapping("/dynamo/files/{id}")
    fun getDynamoFile(@PathVariable id: Int) = dynamoDBMapper.load(DynamoEntity::class.java, id)?.value

}

@DynamoDBTable(tableName = "greeter-table")
data class DynamoEntity(
        @get:DynamoDBHashKey
        var id: Int = 0,
        @get:DynamoDBAttribute
        var value: String = ""
)

@Configuration
class DynamoConfig(
        @Value("\${aws.access.key}")
        private val accessKey: String,
        @Value("\${aws.secret.key}")
        private val secretKey: String
) {
    @Bean
    fun awsCredentials() = BasicAWSCredentials(accessKey, secretKey)

    @Bean
    fun dynamoDbMapperConfig() = DynamoDBMapperConfig.DEFAULT

    @Bean
    fun dynamoDbMapper(dynamoDb: AmazonDynamoDB, dynamoDBMapperConfig: DynamoDBMapperConfig) = DynamoDBMapper(dynamoDb, dynamoDBMapperConfig)

    @Bean
    fun dynamoDb() = AmazonDynamoDBClientBuilder.standard()
            .withCredentials(AWSStaticCredentialsProvider(awsCredentials()))
            .withRegion(Regions.US_EAST_2)
            .build()
}
