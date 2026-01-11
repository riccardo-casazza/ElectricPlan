class ItemTypesController < ApplicationController
  before_action :set_item_type, only: %i[ show edit update destroy ]

  # GET /item_types or /item_types.json
  def index
    @item_types = ItemType.all
  end

  # GET /item_types/1 or /item_types/1.json
  def show
  end

  # GET /item_types/new
  def new
    @new_item_type = ItemType.new
    @item_types = ItemType.all
    render :index
  end

  # GET /item_types/1/edit
  def edit
    @item_types = ItemType.all
    @new_item_type = @item_type
    render :index
  end

  # POST /item_types or /item_types.json
  def create
    @item_type = ItemType.new(item_type_params)

    respond_to do |format|
      if @item_type.save
        format.html { redirect_to item_types_path, notice: "Item type was successfully created." }
        format.json { render :show, status: :created, location: @item_type }
      else
        @new_item_type = @item_type
        @item_types = ItemType.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @item_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /item_types/1 or /item_types/1.json
  def update
    respond_to do |format|
      if @item_type.update(item_type_params)
        format.html { redirect_to item_types_path, notice: "Item type was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @item_type }
      else
        @new_item_type = @item_type
        @item_types = ItemType.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @item_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /item_types/1 or /item_types/1.json
  def destroy
    @item_type.destroy!

    respond_to do |format|
      format.html { redirect_to item_types_path, notice: "Item type was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item_type
      @item_type = ItemType.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def item_type_params
      params.expect(item_type: [ :name ])
    end
end
