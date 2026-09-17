"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Check,
  CheckCircle2,
  CircleAlert,
  Clock3,
  ListTodo,
  LogOut,
  Menu,
  Pencil,
  Plus,
  Search,
  Trash2,
  X,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { FormEvent, useEffect, useMemo, useRef, useState } from "react";
import { ApiClientError, authApi, tasksApi } from "@/lib/api";
import type { Task, TaskInput, TaskStatus } from "@/lib/types";
import { Brand } from "./brand";
import { useToast } from "./providers";

type Filter = "ALL" | TaskStatus;

const statusMeta: Record<TaskStatus, { label: string; tone: string }> = {
  TODO: { label: "À faire", tone: "todo" },
  IN_PROGRESS: { label: "En cours", tone: "progress" },
  DONE: { label: "Terminée", tone: "done" },
};

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Une erreur inattendue est survenue";
}

export function Dashboard() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const [filter, setFilter] = useState<Filter>("ALL");
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [dialogTask, setDialogTask] = useState<Task | "new" | null>(null);
  const [taskToDelete, setTaskToDelete] = useState<Task | null>(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const timer = window.setTimeout(() => setDebouncedSearch(search), 280);
    return () => window.clearTimeout(timer);
  }, [search]);

  const sessionQuery = useQuery({ queryKey: ["session"], queryFn: authApi.session, retry: false });
  const allTasksQuery = useQuery({
    queryKey: ["tasks", "all"],
    queryFn: () => tasksApi.list(),
    enabled: sessionQuery.isSuccess,
  });
  const hasFilters = filter !== "ALL" || Boolean(debouncedSearch.trim());
  const filteredTasksQuery = useQuery({
    queryKey: ["tasks", "filtered", filter, debouncedSearch],
    queryFn: () => tasksApi.list({
      status: filter === "ALL" ? undefined : filter,
      search: debouncedSearch,
    }),
    enabled: sessionQuery.isSuccess && hasFilters,
  });

  useEffect(() => {
    if (sessionQuery.isError) router.replace("/login");
  }, [router, sessionQuery.isError]);

  const invalidateTasks = () => queryClient.invalidateQueries({ queryKey: ["tasks"] });
  const reportApiError = (error: unknown) => {
    if (error instanceof ApiClientError && error.status === 401) {
      queryClient.clear();
      router.replace("/login");
      return;
    }
    showToast(errorMessage(error), "error");
  };

  const saveMutation = useMutation({
    mutationFn: ({ task, input }: { task: Task | "new"; input: TaskInput }) =>
      task === "new" ? tasksApi.create(input) : tasksApi.update(task.id, input),
    onSuccess: (_data, variables) => {
      invalidateTasks();
      setDialogTask(null);
      showToast(variables.task === "new" ? "Tâche ajoutée avec succès" : "Tâche mise à jour");
    },
    onError: reportApiError,
  });

  const deleteMutation = useMutation({
    mutationFn: tasksApi.remove,
    onSuccess: () => {
      invalidateTasks();
      setTaskToDelete(null);
      showToast("Tâche supprimée");
    },
    onError: reportApiError,
  });

  const toggleMutation = useMutation({
    mutationFn: (task: Task) => tasksApi.update(task.id, {
      title: task.title,
      description: task.description ?? "",
      status: task.status === "DONE" ? "TODO" : "DONE",
    }),
    onSuccess: () => invalidateTasks(),
    onError: reportApiError,
  });

  const logoutMutation = useMutation({
    mutationFn: authApi.logout,
    onSuccess: () => {
      queryClient.clear();
      router.replace("/login");
    },
    onError: (error) => showToast(errorMessage(error), "error"),
  });

  const allTasks = useMemo(() => allTasksQuery.data ?? [], [allTasksQuery.data]);
  const tasks = hasFilters ? (filteredTasksQuery.data ?? []) : allTasks;
  const isLoadingTasks = allTasksQuery.isLoading || (hasFilters && filteredTasksQuery.isLoading);
  const taskError = allTasksQuery.error ?? filteredTasksQuery.error;
  const counts = useMemo(() => ({
    all: allTasks.length,
    todo: allTasks.filter((task) => task.status === "TODO").length,
    progress: allTasks.filter((task) => task.status === "IN_PROGRESS").length,
    done: allTasks.filter((task) => task.status === "DONE").length,
  }), [allTasks]);
  const user = sessionQuery.data?.user;
  const firstName = user?.name.split(/\s+/)[0] || "";
  const initials = user?.name.split(/\s+/).slice(0, 2).map((part) => part[0]?.toUpperCase()).join("") || "?";
  const dateLabel = new Intl.DateTimeFormat("fr-FR", { weekday: "long", day: "numeric", month: "long" }).format(new Date());

  useEffect(() => {
    if (taskError instanceof ApiClientError && taskError.status === 401) {
      queryClient.clear();
      router.replace("/login");
    }
  }, [queryClient, router, taskError]);

  if (sessionQuery.isLoading || (sessionQuery.isError && !user)) {
    return <DashboardLoading />;
  }

  return (
    <main className="dashboard-shell">
      <aside className={`sidebar ${mobileMenuOpen ? "open" : ""}`}>
        <Brand inverse />
        <button className="mobile-menu-button" type="button" aria-label="Ouvrir le menu" aria-expanded={mobileMenuOpen} onClick={() => setMobileMenuOpen((value) => !value)}>
          {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
        <nav className="side-nav" aria-label="Navigation principale">
          <button className={`side-link ${filter !== "DONE" ? "active" : ""}`} type="button" onClick={() => { setFilter("ALL"); setMobileMenuOpen(false); }}><ListTodo size={18} /> Mes tâches</button>
          <button className={`side-link ${filter === "DONE" ? "active" : ""}`} type="button" onClick={() => { setFilter("DONE"); setMobileMenuOpen(false); }}><CheckCircle2 size={18} /> Terminées</button>
        </nav>
        <div className="sidebar-profile">
          <span className="avatar">{initials}</span>
          <div><strong>{user?.name}</strong><span>{user?.email}</span></div>
          <button className="logout-button" type="button" title="Se déconnecter" aria-label="Se déconnecter" onClick={() => logoutMutation.mutate()} disabled={logoutMutation.isPending}><LogOut size={17} /></button>
        </div>
      </aside>

      <section className="workspace" id="tasks">
        <header className="dashboard-header">
          <div>
            <span className="eyebrow">{dateLabel}</span>
            <h1>Bonjour {firstName} <span aria-hidden="true">✦</span></h1>
            <p>Avancez sereinement, une tâche à la fois.</p>
          </div>
          <button className="primary-button" type="button" onClick={() => setDialogTask("new")}><Plus size={18} /> Nouvelle tâche</button>
        </header>

        <section className="stats-grid" aria-label="Résumé des tâches">
          <button className={`stat-card ${filter === "ALL" ? "selected" : ""}`} type="button" onClick={() => setFilter("ALL")}><span className="stat-icon coral"><ListTodo size={20} /></span><div><strong>{String(counts.all).padStart(2, "0")}</strong><span>Toutes les tâches</span></div></button>
          <button className={`stat-card ${filter === "IN_PROGRESS" ? "selected" : ""}`} type="button" onClick={() => setFilter("IN_PROGRESS")}><span className="stat-icon gold"><Clock3 size={20} /></span><div><strong>{String(counts.progress).padStart(2, "0")}</strong><span>En cours</span></div></button>
          <button className={`stat-card ${filter === "DONE" ? "selected" : ""}`} type="button" onClick={() => setFilter("DONE")}><span className="stat-icon mint"><CheckCircle2 size={20} /></span><div><strong>{String(counts.done).padStart(2, "0")}</strong><span>Terminées</span></div></button>
        </section>

        <div className="task-toolbar">
          <label className="search-field"><Search size={18} /><span className="sr-only">Rechercher une tâche</span><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Rechercher une tâche…" /></label>
          <div className="filter-pills" aria-label="Filtrer les tâches">
            <FilterButton value="ALL" current={filter} onChange={setFilter}>Toutes <span>{counts.all}</span></FilterButton>
            <FilterButton value="TODO" current={filter} onChange={setFilter}>À faire</FilterButton>
            <FilterButton value="IN_PROGRESS" current={filter} onChange={setFilter}>En cours</FilterButton>
            <FilterButton value="DONE" current={filter} onChange={setFilter}>Terminées</FilterButton>
          </div>
        </div>

        {taskError ? (
          <div className="state-panel error-state"><CircleAlert size={30} /><h2>Impossible de charger vos tâches</h2><p>{errorMessage(taskError)}</p><button type="button" onClick={() => invalidateTasks()}>Réessayer</button></div>
        ) : isLoadingTasks ? (
          <div className="task-list" aria-label="Chargement des tâches">{[1, 2, 3].map((item) => <div className="task-skeleton" key={item} />)}</div>
        ) : tasks.length === 0 ? (
          <div className="state-panel empty-state"><span className="empty-check"><Check size={27} /></span><h2>{hasFilters ? "Aucune tâche ne correspond" : "Votre journée est toute neuve"}</h2><p>{hasFilters ? "Essayez un autre filtre ou une recherche différente." : "Ajoutez votre première tâche et commencez à avancer."}</p>{!hasFilters && <button className="primary-button" type="button" onClick={() => setDialogTask("new")}><Plus size={17} /> Ajouter une tâche</button>}</div>
        ) : (
          <section className="task-list" aria-label="Liste des tâches">
            {tasks.map((task) => {
              const meta = statusMeta[task.status];
              return (
                <article className={`task-card ${task.status === "DONE" ? "task-complete" : ""}`} key={task.id}>
                  <button className={`task-check ${meta.tone}`} aria-label={task.status === "DONE" ? `Rouvrir ${task.title}` : `Terminer ${task.title}`} type="button" onClick={() => toggleMutation.mutate(task)} disabled={toggleMutation.isPending}>
                    {task.status === "DONE" && <Check size={16} strokeWidth={3} />}
                  </button>
                  <div className="task-copy"><h2>{task.title}</h2><p>{task.description || "Aucune description"}</p></div>
                  <span className={`status-badge ${meta.tone}`}>{meta.label}</span>
                  <div className="task-actions">
                    <button type="button" aria-label={`Modifier ${task.title}`} title="Modifier" onClick={() => setDialogTask(task)}><Pencil size={16} /></button>
                    <button className="danger" type="button" aria-label={`Supprimer ${task.title}`} title="Supprimer" onClick={() => setTaskToDelete(task)}><Trash2 size={16} /></button>
                  </div>
                </article>
              );
            })}
          </section>
        )}
      </section>

      {dialogTask && <TaskDialog task={dialogTask} isSaving={saveMutation.isPending} onClose={() => setDialogTask(null)} onSave={(input) => saveMutation.mutate({ task: dialogTask, input })} />}
      {taskToDelete && <DeleteDialog task={taskToDelete} isDeleting={deleteMutation.isPending} onClose={() => setTaskToDelete(null)} onConfirm={() => deleteMutation.mutate(taskToDelete.id)} />}
    </main>
  );
}

function FilterButton({ value, current, onChange, children }: { value: Filter; current: Filter; onChange: (filter: Filter) => void; children: React.ReactNode }) {
  return <button className={`filter-pill ${value === current ? "active" : ""}`} type="button" aria-pressed={value === current} onClick={() => onChange(value)}>{children}</button>;
}

function TaskDialog({ task, isSaving, onClose, onSave }: { task: Task | "new"; isSaving: boolean; onClose: () => void; onSave: (input: TaskInput) => void }) {
  const [form, setForm] = useState<TaskInput>(() => task === "new" ? { title: "", description: "", status: "TODO" } : { title: task.title, description: task.description ?? "", status: task.status });
  const [titleError, setTitleError] = useState("");
  const titleRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    titleRef.current?.focus();
    const closeOnEscape = (event: KeyboardEvent) => event.key === "Escape" && onClose();
    window.addEventListener("keydown", closeOnEscape);
    return () => window.removeEventListener("keydown", closeOnEscape);
  }, [onClose]);

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!form.title.trim()) {
      setTitleError("Le titre est obligatoire");
      return;
    }
    onSave({ ...form, title: form.title.trim(), description: form.description.trim() });
  }

  return (
    <div className="dialog-backdrop" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className="dialog" role="dialog" aria-modal="true" aria-labelledby="task-dialog-title">
        <header><div><span className="eyebrow">{task === "new" ? "Nouvelle priorité" : "Mise à jour"}</span><h2 id="task-dialog-title">{task === "new" ? "Ajouter une tâche" : "Modifier la tâche"}</h2></div><button type="button" aria-label="Fermer" onClick={onClose}><X size={19} /></button></header>
        <form onSubmit={submit}>
          <label className="form-field"><span>Titre</span><input ref={titleRef} className={titleError ? "invalid" : ""} value={form.title} maxLength={150} onChange={(event) => { setTitleError(""); setForm({ ...form, title: event.target.value }); }} placeholder="Ex. Préparer la présentation" />{titleError && <small className="field-error">{titleError}</small>}</label>
          <label className="form-field"><span>Description <em>optionnelle</em></span><textarea value={form.description} maxLength={5000} onChange={(event) => setForm({ ...form, description: event.target.value })} placeholder="Ajoutez quelques détails utiles…" rows={4} /></label>
          <label className="form-field"><span>Statut</span><select value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value as TaskStatus })}><option value="TODO">À faire</option><option value="IN_PROGRESS">En cours</option><option value="DONE">Terminée</option></select></label>
          <footer><button className="secondary-button" type="button" onClick={onClose}>Annuler</button><button className="primary-button" type="submit" disabled={isSaving}>{isSaving ? <span className="spinner" /> : task === "new" ? "Ajouter la tâche" : "Enregistrer"}</button></footer>
        </form>
      </section>
    </div>
  );
}

function DeleteDialog({ task, isDeleting, onClose, onConfirm }: { task: Task; isDeleting: boolean; onClose: () => void; onConfirm: () => void }) {
  return (
    <div className="dialog-backdrop" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className="dialog confirm-dialog" role="alertdialog" aria-modal="true" aria-labelledby="delete-title" aria-describedby="delete-description">
        <span className="confirm-icon"><Trash2 size={22} /></span>
        <h2 id="delete-title">Supprimer cette tâche ?</h2>
        <p id="delete-description">« {task.title} » sera supprimée définitivement.</p>
        <footer><button className="secondary-button" type="button" onClick={onClose}>Conserver</button><button className="danger-button" type="button" onClick={onConfirm} disabled={isDeleting}>{isDeleting ? <span className="spinner" /> : "Supprimer"}</button></footer>
      </section>
    </div>
  );
}

function DashboardLoading() {
  return <main className="dashboard-loading"><span className="brand-icon"><Check size={18} strokeWidth={3} /></span><span className="spinner dark" /><p>Préparation de votre espace…</p></main>;
}
