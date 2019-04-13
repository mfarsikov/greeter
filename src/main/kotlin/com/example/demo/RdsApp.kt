package com.example.demo

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RestController
import javax.persistence.Entity
import javax.persistence.Id
import kotlin.random.Random

@RestController
class RdsController(
        val counterRepository: CounterRepository
) {

    @PostMapping("/rds/increase-counter")
    fun getFile(): Counter {
        val previous = counterRepository.findAll().firstOrNull() ?: Counter(count = 0)
        val next = previous.let { it.copy(count = it.count + 1) }
        return counterRepository.save(next)
    }
}

@Entity
data class Counter(
        @Id
        val id: Int = Random.nextInt(),
        val count: Int
)

@Repository
interface CounterRepository : JpaRepository<Counter, Int>
