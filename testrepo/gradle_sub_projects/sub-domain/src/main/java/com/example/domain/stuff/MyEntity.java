package com.example.domain.stuff;

import java.io.Serializable;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;

import org.hibernate.annotations.Immutable;

@Entity
@Immutable
public class MyEntity implements Serializable {

	private static final long serialVersionUID = 1L;

	@Id
    @Column
	private long id;

    @Column
	private Long type;

	protected MyEntity() { }

	public MyEntity(long id, Long type) {
		this.id = id;
		this.type = type;
	}

	public Long getId() {
        return id;
    }

	public Long getType() {
		return this.type;
	}

}
