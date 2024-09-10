class AuthenticationsController < ApplicationController
  require_unauthenticated_access only: [:new, :create]
  before_action :ensure_manual_login_allowed, except: :destroy

  layout "public"

  def new
  end

  def create
    supabase_client = create_supabase_client

    begin
      # Attempt to sign in with Supabase
      supabase_response = supabase_client.auth.sign_in_with_password(
        email: params[:email],
        password: params[:password]
      )

      if supabase_response.user
        # Supabase authentication successful
        person = Person.find_or_create_by(email: params[:email]) do |new_person|
          # Set additional attributes for new users if needed
          new_person.name = supabase_response.user.user_metadata['full_name']
          # ... other attributes ...
        end

        user = person.personable || create_user_for_person(person)

        # Use existing session management
        login_as(person, credential: user.password_credential)
        redirect_to root_path
        return
      else
        # Supabase authentication failed
        flash.now[:alert] = "Invalid email or password"
        render :new, status: :unprocessable_entity
      end

    rescue => e
      # Handle any Supabase API errors
      Rails.logger.error "Supabase authentication error: #{e.message}"
      flash.now[:alert] = "An error occurred during authentication"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout_current
    redirect_to login_path
  end

  private

  def create_supabase_client
    # Initialize and return a Supabase client
    # You'll need to add the supabase-ruby gem to your Gemfile
    Supabase::Client.new(
      ENV['SUPABASE_URL'],
      ENV['SUPABASE_API_KEY']
    )
  end

  def create_user_for_person(person)
    # Create a new user associated with the person
    # Adjust this based on your app's user model and associations
    user = User.create!(
      # Set user attributes as needed
    )
    person.update(personable: user)
    user
  end
end