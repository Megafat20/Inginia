<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $admins = [
            [
                'name' => 'Abdoul Malick',
                'email' => 'hiam.amhi@inginia.com',
                'password' => Hash::make('123456789'),
                'role' => 'admin',
                'phone' => '97800256',
                'is_verified' => true,
            ],
            [
                'name' => 'Abdoul Fataou ',
                'email' => 'superfataou13@inginia.com',
                'password' => Hash::make('123456789'),
                'role' => 'admin',
                'is_verified' => true,
            ],
        ];

        foreach ($admins as $admin) {
            User::updateOrCreate(
                ['email' => $admin['email']],
                [
                    'name' => $admin['name'],
                    'password' => $admin['password'], // Le hash sera mis à jour
                    'role' => $admin['role'],
                    'phone' => $admin['phone'] ?? null,
                    'is_verified' => true,
                ]
            );
        }
    }
}
