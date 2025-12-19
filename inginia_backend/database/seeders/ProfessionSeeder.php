<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ProfessionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $professions = [
            ['name' => 'Électricien', 'icon' => '⚡'],
        ['name' => 'Plombier', 'icon' => '🔧'],
        ['name' => 'Mécanicien', 'icon' => '🚗'],
        ['name' => 'Informaticien', 'icon' => '💻'],
        ['name' => 'Froid', 'icon' => '❄️'],
        ['name' => 'Peintre', 'icon' => '🎨'],
        ['name' => 'Menuisier', 'icon' => '🪚'],
        ['name' => 'Couvreur', 'icon' => '🏠'],
        ['name' => 'Chauffeur', 'icon' => '🚖'],
        ['name' => 'Coiffeur', 'icon' => '✂️'],
        ['name' => 'Jardinier', 'icon' => '🌱'],
        ['name' => 'Photographe', 'icon' => '📷'],
        ['name' => 'Maçon', 'icon' => '🧱'],
        ['name' => 'Serrurier', 'icon' => '🔒'],
        ['name' => 'Technicien', 'icon' => '🛠️'],
        ];

        foreach ($professions as $profession) {
            DB::table('professions')->insert([
                'name' => $profession['name'],
                'icon' => $profession['icon'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $this->command->info('Table professions remplie avec succès !');
    }
}
