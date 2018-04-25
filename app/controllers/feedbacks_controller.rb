class FeedbacksController < ApplicationController
  #führe die Methoden/Funktionen immer aus bevor eine andere Methode/Funktion ausgeführt wird
  before_action :set_user
  before_action :set_group
  #nur vor create
  before_action :convertFeedback, only: [:create]
  #nur vor show, edit, update, destroy
  before_action :set_feedback, only: [:show, :edit, :update, :destroy]
  layout 'empty'
  # GET /feedbacks
  # GET /feedbacks.json
  #laden aller Feedbacks, der zugehörigen gruppe + Aufrufen JS-template
  def index
    @feedbacks = Feedback.where(group_id: @group.id)

    respond_to do |format|
      format.js {}
      format.html {}
      @students = Student.where(:group_id => @group.id)
      format.pdf {
        render pdf: "Zugangsdaten der Probandengruppe #{@group.name}",
               template: "students/index.pdf.erb"
      }
      format.text {
        render 'index', :formats => [:js], content_type: 'text/javascript'
      }
    end
  end

  # GET /feedbacks/1
  # GET /feedbacks/1.json
  #anzeigen eines Feedbacks
  def show
  end

  # GET /feedbacks/new
  #erzeugen eines neuen Feedbacks
  def new
    @feedback = Feedback.new
  end

  # GET /feedbacks/1/edit
  #Verändern eines Feedbacks (Standardfunktion)
  def edit
  end

  # POST /feedbacks
  # POST /feedbacks.json
  #speichern eines Feedbacks
  def create
    feedback_params[:feedbacktext] = feedback_params[:feedbacktext].gsub!("\n", "<br/>")

    @feedback = @group.feedbacks.new(feedback_params)

    respond_to do |format|
      #Wenn gespeichert -> weiterladen auf frontendseite und bedanken
      if @feedback.save

        format.html {
          @student = Student.find_by_id(session[:student_id])
          @student.feedback_send = true
          @student.save
          flash[:notice]= 'Vielen Dank für dein Feedback :)'
          redirect_to '/frontend'

        }
        format.json { render :show, status: :created, location: @feedback }
      else
        #wenn Feedback sollte nicht leer sein
        format.html {
          render :new
          flash[:notice]= 'Feedback sollte nicht leer sein ;)'
        }
        format.json { render json: @feedback.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /feedbacks/1
  # PATCH/PUT /feedbacks/1.json
  #Updaten von feedback (Standardfunktion)
  def update
    respond_to do |format|
      if @feedback.update(feedback_params)
        format.html { redirect_to @feedback, notice: 'Feedback was successfully updated.' }
        format.json { render :show, status: :ok, location: @feedback }
      else
        format.html { render :edit }
        format.json { render json: @feedback.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /feedbacks/1
  # DELETE /feedbacks/1.json
  #Updaten von feedback (Standardfunktion)
  def destroy
    @feedback.destroy
    respond_to do |format|
      format.html { redirect_to feedbacks_url, notice: 'Feedback was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  #Anpassen des Feedbacktexts auf html (Zeilenumbruch parsen)
  def convertFeedback
    feedback_params[:feedbacktext] = feedback_params[:feedbacktext].gsub!("\n", "<br/>")
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_feedback
      @feedback = Feedback.find(params[:id])
    end

    def set_user
      @user = User.find(params[:user_id])
    end

    def set_group
      @group = Group.find(params[:group_id])
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def feedback_params
      params.require(:feedback).permit(:feedbacktext)
    end


    def is_allowed
      #check if user is allowed
      #@result exists only before update => student can only update a result
      unless (!@login_user.nil? && @login_user.hasCapability?("admin")) || (!@login_user.nil? && params.has_key?(:user_id) &&
          (@login_user.id == params[:user_id].to_i)) ||((@login_student.id == @result.student.id) && !@login_student.nil?)
        redirect_to '/mainapp'
      end
  end
end
