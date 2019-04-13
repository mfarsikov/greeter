package com.example.demo

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import kotlin.random.Random

@RestController
class GreeterController{
    private val rand = Random.nextInt()

    @GetMapping("/hello")
    fun hello(@RequestParam name: String?) = "${rand}: Hello ${name ?: "vasya"}!"

}