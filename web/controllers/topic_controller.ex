defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  alias Discuss.Topic

  # Ensure users are logged in when accessing certain parts of the application
  plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
  plug :check_topic_owner when action in [:update, :edit, :delete]

  def index(conn, _params) do
      IO.puts("conn.assigns:")
      IO.inspect(conn.assigns)
      topics = Repo.all(Topic)
      render conn, "index.html", topics: topics
  end

  def show(conn, %{"id" => topic_id}) do
      topic = Repo.get!(Topic, topic_id)
      render conn, "show.html", topic: topic
  end

  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})
    render conn, "new.html", changeset: changeset
  end

  # Note that params maps are string: value
  def create(conn, %{"topic" => topic}) do
    # conn.assigns[:user]
    # changeset = Topic.changeset(%Topic{}, topic)

    changeset = conn.assigns.user
      |> build_assoc(:topics)
      |> Topic.changeset(topic)

    case Repo.insert(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic Created")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Invalid Submission")
        |> render("new.html", changeset: changeset)
    end

  end

  def edit(conn, %{"id" => topic_id}) do
    # Pull a single record from Topic with topic_id
    topic = Repo.get(Topic, topic_id)

    # Create a changeset that looks like `topic`
    changeset = Topic.changeset(topic)

    render conn, "edit.html", changeset: changeset, topic: topic
  end

  def update(conn, %{"id" => topic_id, "topic" => topic}) do
    old_topic = Repo.get(Topic, topic_id)
    changeset = Topic.changeset(old_topic, topic)

    case Repo.update(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic Updated")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Invalid Submission")
        |> render("edit.html", changeset: changeset, topic: old_topic)
    end
  end

  def delete(conn, %{"id" => topic_id}) do
    # automatically generates an error if something goes wrong
    Repo.get!(Topic, topic_id) |> Repo.delete!

    conn
    |> put_flash(:info, "Topic Deleted")
    |> redirect(to: topic_path(conn, :index))
  end

  # Remember this is a plug - not the same params as edit/delete etc
  # those other guys takes params from the router
  def check_topic_owner(conn, _params) do
    %{params: %{"id" => topic_id}} = conn

    if Repo.get(Topic, topic_id).user_id == conn.assigns.user.id do
      conn
    else
      conn
      |> put_flash(:error, "You cannot edit this")
      |> redirect(to: topic_path(conn, :index))
      |> halt()
    end
  end
end
