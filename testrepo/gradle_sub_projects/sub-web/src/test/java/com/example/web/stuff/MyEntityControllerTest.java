package com.example.web.stuff;

import static org.hamcrest.Matchers.equalTo;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.Before;
import org.junit.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import com.example.domain.stuff.MyEntity;
import com.example.domain.stuff.MyEntityRepository;

public class MyEntityControllerTest {

    @Mock
    private MyEntityRepository myEntityRepository;

    @InjectMocks
    private MyEntityController controller;

    private MockMvc mockMvc;

    private final long entityId = 99L;
    private MyEntity myEntity;

    @Before
    public void setUp() {
        MockitoAnnotations.initMocks(this);
        this.mockMvc = MockMvcBuilders.standaloneSetup(controller).build();

        myEntity = new MyEntity(1L, 1L);
        Mockito.when(this.myEntityRepository.findById(entityId)).thenReturn(myEntity);
    }

    @Test
    public void byId() throws Exception {
        this.mockMvc.perform(get("/entities/" + entityId))
            .andDo(print())
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id", equalTo(myEntity.getId().intValue())));
    }

}
