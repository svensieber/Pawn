-- Pawn UI for Vanilla (minimal stub)
-- The actual UI will be implemented later

PawnUIFrame = nil

function PawnUI_OnLoad()
	-- UI initialization will go here
end

function PawnUI_Show()
	if not PawnUIFrame then
		VgerCore.Message("Pawn UI is not yet implemented for Vanilla.")
		return
	end
	PawnUIFrame:Show()
end

function PawnUI_Hide()
	if PawnUIFrame then
		PawnUIFrame:Hide()
	end
end