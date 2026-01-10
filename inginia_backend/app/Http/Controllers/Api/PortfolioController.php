<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Portfolio;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PortfolioController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:5120', // 5MB max
            'title' => 'nullable|string|max:100',
            'description' => 'nullable|string|max:255',
        ]);

        $user = auth()->user();
        if (!$user || $user->role !== 'prestataire') {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $path = $request->file('image')->store('portfolios', 'public');

        $portfolio = Portfolio::create([
            'provider_id' => $user->id,
            'image_path' => basename($path),
            'title' => $request->title,
            'description' => $request->description,
        ]);

        return response()->json($portfolio, 201);
    }

    public function destroy($id)
    {
        $portfolio = Portfolio::findOrFail($id);

        if ($portfolio->provider_id !== auth()->id()) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        Storage::disk('public')->delete('portfolios/' . $portfolio->image_path);
        $portfolio->delete();

        return response()->json(['message' => 'Image supprimée']);
    }
}
