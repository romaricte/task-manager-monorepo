package com.romadev.task_manager.task;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TaskRepository extends JpaRepository<Task, Long> {

    @Query("""
            select task from Task task
            where task.owner.id = :ownerId
              and (:status is null or task.status = :status)
              and (:search is null
                   or lower(task.title) like lower(concat('%', :search, '%'))
                   or lower(coalesce(task.description, '')) like lower(concat('%', :search, '%')))
            order by task.createdAt desc
            """)
    List<Task> findAllForOwner(
            @Param("ownerId") Long ownerId,
            @Param("status") TaskStatus status,
            @Param("search") String search
    );

    Optional<Task> findByIdAndOwnerId(Long id, Long ownerId);
}
