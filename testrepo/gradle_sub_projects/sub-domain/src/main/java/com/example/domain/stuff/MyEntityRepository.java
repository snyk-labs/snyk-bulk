package com.example.domain.stuff;

import java.util.List;

import org.springframework.data.repository.Repository;

public interface MyEntityRepository extends Repository<MyEntity, Long> {

	List<MyEntity> findAll();

    MyEntity findById(long id);

}
