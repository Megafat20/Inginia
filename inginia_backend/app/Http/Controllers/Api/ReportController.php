<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\Reservation;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'reported_id' => 'required|exists:users,id',
            'reservation_id' => 'nullable|exists:reservations,id',
            'reason' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        $report = Report::create([
            'reporter_id' => auth()->id(),
            'reported_id' => $request->reported_id,
            'reservation_id' => $request->reservation_id,
            'reason' => $request->reason,
            'description' => $request->description,
        ]);

        return response()->json([
            'message' => 'Signalement envoyé avec succès. Notre équipe va l\'étudier.',
            'report' => $report
        ], 201);
    }
}
