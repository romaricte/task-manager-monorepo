package com.romadev.task_manager.task;

import com.romadev.task_manager.common.NotFoundException;
import com.romadev.task_manager.user.User;
import com.romadev.task_manager.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final UserRepository userRepository;

    public TaskService(TaskRepository taskRepository, UserRepository userRepository) {
        this.taskRepository = taskRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<TaskResponse> findAll(String email, TaskStatus status, String search) {
        User owner = findUser(email);
        String normalizedSearch = search == null || search.isBlank() ? null : search.trim();
        return taskRepository.findAllForOwner(owner.getId(), status, normalizedSearch).stream()
                .map(TaskResponse::from)
                .toList();
    }

    @Transactional
    public TaskResponse create(String email, TaskRequest request) {
        User owner = findUser(email);
        Task task = new Task(
                request.title().trim(),
                normalizeDescription(request.description()),
                request.status(),
                owner
        );
        return TaskResponse.from(taskRepository.save(task));
    }

    @Transactional
    public TaskResponse update(String email, Long taskId, TaskRequest request) {
        User owner = findUser(email);
        Task task = taskRepository.findByIdAndOwnerId(taskId, owner.getId())
                .orElseThrow(() -> new NotFoundException("Tâche introuvable"));
        task.update(
                request.title().trim(),
                normalizeDescription(request.description()),
                request.status()
        );
        return TaskResponse.from(taskRepository.saveAndFlush(task));
    }

    @Transactional
    public void delete(String email, Long taskId) {
        User owner = findUser(email);
        Task task = taskRepository.findByIdAndOwnerId(taskId, owner.getId())
                .orElseThrow(() -> new NotFoundException("Tâche introuvable"));
        taskRepository.delete(task);
    }

    private User findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new NotFoundException("Utilisateur introuvable"));
    }

    private String normalizeDescription(String description) {
        if (description == null || description.isBlank()) {
            return null;
        }
        return description.trim();
    }
}
