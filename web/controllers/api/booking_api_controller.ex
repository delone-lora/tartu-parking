defmodule TartuParking.BookingAPIController do
  use TartuParking.Web, :controller
  alias TartuParking.{Repo, Booking, User, Parking}
  alias Ecto.{Changeset}
  import Ecto.Query, only: [from: 2]

  def index(conn, _params) do

    user = conn.assigns.current_user

    bookings =
      Repo.all(from t in Booking, where: t.user_id == ^user.id, select: t)
      |> Enum.map(
           fn (booking) ->
             parking = Repo.get(Parking, booking.parking_id)

             %{
               "id": booking.id,
               "parking": parking,
               "status": booking.status
             }
           end
         )

    conn
    |> put_status(200)
    |> json(bookings)
  end

  def create(conn, %{"parking_id" => parking_id}) do

    user = conn.assigns.current_user

    changeset =
      Booking.changeset(
        %Booking{},
        %{
          status: "started",
          user_id: user.id,
          parking_id: parking_id
        }
      )

    {status, response} =
      case Repo.insert(changeset) do
        {:error, msg} ->
          {500, %{"message": "Internal error"}}

        {:ok, booking} ->
          {201, %{"message": "Booking created", "booking_id": booking.id}}
      end

    conn
    |> put_status(status)
    |> json(response)
  end

  def create(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{"message": "Missing Parking ID"})
  end


  def update(conn, %{"id" => booking_id}) do

    user = conn.assigns.current_user

    query = from b in Booking, where: b.id == ^booking_id and b.user_id == ^user.id
    booking = query
              |> Repo.all()
              |> List.first()

    {status, response} =
      case booking do
        nil ->
          {404, %{"message": "Booking not found"}}

        _ ->
          booking = Ecto.Changeset.change booking, status: "finished"

          case Repo.update booking do
            {:ok, struct} ->
              {200, %{"message": "Booking finished"}}

            {:error, changeset} ->
              {500, %{"message": "Internal error"}}
          end
      end

    conn
    |> put_status(status)
    |> json(response)
  end
end