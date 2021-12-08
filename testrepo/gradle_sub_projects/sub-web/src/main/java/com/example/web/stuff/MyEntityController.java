package com.example.web.stuff;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.domain.stuff.MyEntity;
import com.example.domain.stuff.MyEntityRepository;

@Controller
@Transactional(readOnly = true)
public class MyEntityController {

    private final MyEntityRepository myEntityRepository;

    @Autowired
    public MyEntityController(MyEntityRepository myEntityRepository) {
        this.myEntityRepository = myEntityRepository;
    }

    @GetMapping("/entities/{id}")
    @ResponseBody
    public MyEntity id(@PathVariable long id) {
        return myEntityRepository.findById(id);
    }

}
