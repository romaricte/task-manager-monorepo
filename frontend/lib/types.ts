export type TaskStatus = "TODO" | "IN_PROGRESS" | "DONE";

export type User = {
  id: number;
  name: string;
  email: string;
};

export type Task = {
  id: number;
  title: string;
  description: string | null;
  status: TaskStatus;
  createdAt: string;
  updatedAt: string;
};

export type TaskInput = {
  title: string;
  description: string;
  status: TaskStatus;
};

export type ApiErrorBody = {
  message?: string;
  validationErrors?: Record<string, string> | null;
};
