package com.example.domain.stuff;

import java.util.List;

import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@DataJpaTest
@ActiveProfiles("testing")
public class MyEntityRepositoryTest {

    private static final Long ID_TEST_ENTITY = 11111L;

    @Autowired
    private MyEntityRepository myEntityRepository;

    @Test
    public void findAll() {
        // execute
        List<MyEntity> entities = myEntityRepository.findAll();
        // verify
        Assert.assertEquals(2, entities.size());
    }

    @Test
    public void findById() {
        // execute
        MyEntity myEntity = myEntityRepository.findById(ID_TEST_ENTITY);
        // verify
        Assert.assertEquals(11L, myEntity.getType().longValue());
    }

}
