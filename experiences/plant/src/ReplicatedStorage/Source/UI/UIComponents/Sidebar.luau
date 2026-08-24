--!strict

--[[
	UIComponent for a list item in the Categories view (shop and seed selection)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelViewport = require(script.Parent.ModelViewport)
local SidebarActionButton = require(script.Parent.SidebarActionButton)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getMetadataFromItemId = require(ReplicatedStorage.Source.Utility.Farm.getMetadataFromItemId)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local prefabInstance: Frame = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "SidebarFramePrefab")

export type SidebarProperties = {
	primaryColor: Color3,
	secondaryColor: Color3,
	footerDescription: string,
	footerIconId: number?,
}

local Sidebar = {}
Sidebar.__index = Sidebar

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Frame,
		_actionButton: SidebarActionButton.ClassType,
		_primaryModelViewport: ModelViewport.ClassType?,
		_secondaryModelViewport: ModelViewport.ClassType?,
	},
	Sidebar
))

function Sidebar.new(properties: SidebarProperties): ClassType
	local instance = prefabInstance:Clone()

	local self = {
		_instance = instance,
		_actionButton = SidebarActionButton.new({
			primaryColor = properties.primaryColor,
			secondaryColor = properties.secondaryColor,
		}),
		_primaryModelViewport = nil,
		_secondaryModelViewport = nil,
	}
	setmetatable(self, Sidebar)

	self:_setup(properties)

	return self
end

function Sidebar.setParent(self: ClassType, parent: Instance)
	self._instance.Parent = parent
end

function Sidebar._setup(self: ClassType, properties: SidebarProperties)
	self:_setFooterDescriptionText(properties.footerDescription, properties.footerIconId)
	self:_setPrimaryColor(properties.primaryColor)

	self._actionButton:setParent(self._instance)
	self._actionButton:setEnabled(false)
end

function Sidebar.setInfo(self: ClassType, itemId: string)
	local metadata = getMetadataFromItemId(itemId)

	self:_setTitle(metadata.name)
	self:_setDescription(metadata.descriptionLong)
	self:_setPrimaryPreviewModel(metadata.itemModel)
	self:_setSecondaryPreviewModel(metadata.secondaryModel)
end

function Sidebar._setPrimaryPreviewModel(self: ClassType, previewModel: Model?)
	local primaryModelViewportMaybe = self._primaryModelViewport
	if primaryModelViewportMaybe then
		local primaryModelViewport = primaryModelViewportMaybe :: ModelViewport.ClassType
		primaryModelViewport:destroy()
		self._primaryModelViewport = nil
	end

	if previewModel then
		local modelViewportHolder: Frame =
			getInstance(self._instance, "DetailsFrame", "PrimaryIconFrame", "ModelViewportHolder")
		local modelViewport = ModelViewport.new({
			model = previewModel,
		})
		modelViewport:setParent(modelViewportHolder)
		self._primaryModelViewport = modelViewport
	end
end

function Sidebar._setSecondaryPreviewModel(self: ClassType, previewModel: Model?)
	local secondaryModelViewportMaybe = self._secondaryModelViewport
	if secondaryModelViewportMaybe then
		local secondaryModelViewport = secondaryModelViewportMaybe :: ModelViewport.ClassType
		secondaryModelViewport:destroy()
		self._secondaryModelViewport = nil
	end

	if previewModel then
		local modelViewportHolder: Frame =
			getInstance(self._instance, "DetailsFrame", "SecondaryIconFrame", "ModelViewportHolder")
		local modelViewport = ModelViewport.new({
			model = previewModel,
		})
		modelViewport:setParent(modelViewportHolder)

		self._secondaryModelViewport = modelViewport
	end
end

function Sidebar._setTitle(self: ClassType, name: string?)
	local titleTextLabel: TextLabel = getInstance(self._instance, "DetailsFrame", "InfoFrame", "TitleTextLabel")
	titleTextLabel.Text = name or ""
end

function Sidebar._setDescription(self: ClassType, description: string?)
	local descriptionTextLabel: TextLabel = getInstance(self._instance, "DetailsFrame", "InfoFrame", "InfoTextLabel")
	descriptionTextLabel.Text = description or ""
end

-- TODO: Generalize footer concept (e.g. implement CoinIndicatorFooter, ItemsOwnedFooter)
function Sidebar.setFooterText(self: ClassType, optionalText: string?)
	local text = optionalText or ""
	local footerTextLabel: TextLabel = getInstance(self._instance, "FooterFrame", "FooterTextLabel")
	local footerDescriptionTextLabel: TextLabel =
		getInstance(self._instance, "FooterFrame", "FooterDescriptionFrame", "FooterDescriptionTextLabel")

	footerTextLabel.Text = text
	footerDescriptionTextLabel.Visible = #text > 0
end

function Sidebar._setFooterDescriptionText(self: ClassType, text: string?, iconId: number?)
	local footerDescriptionFrame: Frame = getInstance(self._instance, "FooterFrame", "FooterDescriptionFrame")
	local footerDescriptionTextLabel: TextLabel = getInstance(footerDescriptionFrame, "FooterDescriptionTextLabel")
	footerDescriptionTextLabel.Text = text or ""

	local descriptionImageLabel: ImageLabel = getInstance(footerDescriptionFrame, "FooterDescriptionImageLabel")
	descriptionImageLabel.Visible = if iconId then true else false
	descriptionImageLabel.Image = if iconId
		then PlayerFacingString.ImageAsset.Prefix .. tostring(iconId)
		else PlayerFacingString.ImageAsset.None
end

function Sidebar._setPrimaryColor(self: ClassType, color: Color3)
	local titleTextLabel: TextLabel = getInstance(self._instance, "DetailsFrame", "InfoFrame", "TitleTextLabel")
	local footerTextLabel: TextLabel = getInstance(self._instance, "FooterFrame", "FooterTextLabel")

	titleTextLabel.TextColor3 = color
	footerTextLabel.TextColor3 = color
end

function Sidebar._setSecondaryColor(self: ClassType, color: Color3)
	local primaryIconBackgroundFrame: Frame = getInstance(self._instance, "DetailsFrame", "PrimaryIconFrame")
	primaryIconBackgroundFrame.BackgroundColor3 = color
end

function Sidebar.reset(self: ClassType)
	local titleTextLabel: TextLabel = getInstance(prefabInstance, "DetailsFrame", "InfoFrame", "TitleTextLabel")
	local infoTextLabel: TextLabel = getInstance(prefabInstance, "DetailsFrame", "InfoFrame", "InfoTextLabel")
	local footerTextLabel: TextLabel = getInstance(prefabInstance, "FooterFrame", "FooterTextLabel")
	self:_setTitle(titleTextLabel.Text)
	self:_setDescription(infoTextLabel.Text)
	self:setFooterText(footerTextLabel.Text)
	self:_setPrimaryPreviewModel(nil)
	self:_setSecondaryPreviewModel(nil)
	self._actionButton:reset()
end

function Sidebar.getActionButton(self: ClassType)
	return self._actionButton
end

function Sidebar.destroy(self: ClassType)
	local primaryModelViewportMaybe = self._primaryModelViewport
	if primaryModelViewportMaybe then
		local primaryModelViewport = primaryModelViewportMaybe :: ModelViewport.ClassType
		primaryModelViewport:destroy()
	end

	local secondaryModelViewportMaybe = self._secondaryModelViewport
	if secondaryModelViewportMaybe then
		local secondaryModelViewport = secondaryModelViewportMaybe :: ModelViewport.ClassType
		secondaryModelViewport:destroy()
	end

	self._actionButton:destroy()

	if self._instance.Parent then
		self._instance:Destroy()
	end
end

return Sidebar
