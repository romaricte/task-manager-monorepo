import '../core/api_client.dart';
import '../models/task.dart';

class TaskRepository {
  const TaskRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TaskItem>> fetchTasks({
    TaskStatus? status,
    String search = '',
  }) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/api/tasks',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      return response.data!
          .map((json) => TaskItem.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw _apiClient.mapError(error);
    }
  }

  Future<TaskItem> createTask(TaskDraft draft) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/tasks',
        data: draft.toJson(),
      );
      return TaskItem.fromJson(response.data!);
    } catch (error) {
      throw _apiClient.mapError(error);
    }
  }

  Future<TaskItem> updateTask(int id, TaskDraft draft) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/api/tasks/$id',
        data: draft.toJson(),
      );
      return TaskItem.fromJson(response.data!);
    } catch (error) {
      throw _apiClient.mapError(error);
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _apiClient.dio.delete<void>('/api/tasks/$id');
    } catch (error) {
      throw _apiClient.mapError(error);
    }
  }
}
